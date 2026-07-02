import { createClient } from "npm:@supabase/supabase-js";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type Provider = "stripe" | "paypal";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const jwt = authHeader.replace("Bearer ", "").trim();
  if (!jwt) return jsonResponse({ error: "Missing authorization" }, 401);

  const supabaseUrl = requiredEnv("SUPABASE_URL");
  const anonKey = requiredEnv("SUPABASE_ANON_KEY");
  const serviceRoleKey = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
  });
  const adminClient = createClient(supabaseUrl, serviceRoleKey);

  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return jsonResponse({ error: "Invalid user session" }, 401);
  }

  try {
    const body = await req.json();
    const provider = parseProvider(body.provider);
    const amountCents = Number(Deno.env.get("LISTENER_AMOUNT_CENTS") ?? "999");
    const currency = (Deno.env.get("LISTENER_CURRENCY") ?? "myr")
      .toLowerCase();

    const { data: payment, error: paymentError } = await adminClient
      .from("subscription_payments")
      .insert({
        patient_id: userData.user.id,
        provider,
        amount_cents: amountCents,
        currency,
        status: "pending",
      })
      .select("id")
      .single();

    if (paymentError) throw paymentError;

    const checkout = provider === "stripe"
      ? await createStripeCheckout({
        paymentId: payment.id,
        amountCents,
        currency,
      })
      : await createPaypalCheckout({
        paymentId: payment.id,
        amountCents,
        currency,
      });

    const { error: updateError } = await adminClient
      .from("subscription_payments")
      .update({
        provider_checkout_id: checkout.checkoutId,
        checkout_url: checkout.url,
      })
      .eq("id", payment.id);

    if (updateError) throw updateError;

    return jsonResponse({
      checkoutUrl: checkout.url,
      paymentId: payment.id,
    });
  } catch (error) {
    console.error("subscription checkout error", error);
    return jsonResponse({ error: "Unable to start checkout" }, 500);
  }
});

function parseProvider(value: unknown): Provider {
  if (value === "stripe" || value === "paypal") return value;
  throw new Error("Unsupported payment provider");
}

async function createStripeCheckout({
  paymentId,
  amountCents,
  currency,
}: {
  paymentId: string;
  amountCents: number;
  currency: string;
}) {
  const secretKey = requiredEnv("STRIPE_SECRET_KEY");
  const successUrl = requiredEnv("SUBSCRIPTION_PAYMENT_SUCCESS_URL");
  const cancelUrl = requiredEnv("SUBSCRIPTION_PAYMENT_CANCEL_URL");
  const priceId = Deno.env.get("STRIPE_MINDLY_PREMIUM_PRICE_ID");

  const body = new URLSearchParams({
    mode: priceId ? "subscription" : "payment",
    success_url: successUrl,
    cancel_url: cancelUrl,
    "metadata[payment_id]": paymentId,
  });

  if (priceId) {
    body.set("line_items[0][price]", priceId);
    body.set("line_items[0][quantity]", "1");
  } else {
    body.set("line_items[0][quantity]", "1");
    body.set("line_items[0][price_data][currency]", currency);
    body.set(
      "line_items[0][price_data][product_data][name]",
      "Mindly Premium",
    );
    body.set("line_items[0][price_data][unit_amount]", String(amountCents));
  }

  const response = await fetch("https://api.stripe.com/v1/checkout/sessions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${secretKey}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body,
  });

  const data = await response.json();
  if (!response.ok || typeof data.url !== "string") {
    console.error("Stripe checkout error", data);
    throw new Error("Stripe checkout failed");
  }

  return { checkoutId: data.id as string, url: data.url as string };
}

async function createPaypalCheckout({
  paymentId,
  amountCents,
  currency,
}: {
  paymentId: string;
  amountCents: number;
  currency: string;
}) {
  const clientId = requiredEnv("PAYPAL_CLIENT_ID");
  const secret = requiredEnv("PAYPAL_SECRET");
  const baseUrl = Deno.env.get("PAYPAL_BASE_URL") ??
    "https://api-m.sandbox.paypal.com";
  const returnUrl = requiredEnv("SUBSCRIPTION_PAYMENT_SUCCESS_URL");
  const cancelUrl = requiredEnv("SUBSCRIPTION_PAYMENT_CANCEL_URL");

  const tokenResponse = await fetch(`${baseUrl}/v1/oauth2/token`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${btoa(`${clientId}:${secret}`)}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });
  const tokenData = await tokenResponse.json();
  if (!tokenResponse.ok || typeof tokenData.access_token !== "string") {
    console.error("PayPal token error", tokenData);
    throw new Error("PayPal token failed");
  }

  const orderResponse = await fetch(`${baseUrl}/v2/checkout/orders`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${tokenData.access_token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      intent: "CAPTURE",
      purchase_units: [{
        custom_id: paymentId,
        amount: {
          currency_code: currency.toUpperCase(),
          value: (amountCents / 100).toFixed(2),
        },
      }],
      application_context: {
        return_url: returnUrl,
        cancel_url: cancelUrl,
      },
    }),
  });

  const orderData = await orderResponse.json();
  const approveLink = Array.isArray(orderData.links)
    ? orderData.links.find((link: { rel?: string }) => link.rel === "approve")
    : null;

  if (!orderResponse.ok || typeof approveLink?.href !== "string") {
    console.error("PayPal order error", orderData);
    throw new Error("PayPal order failed");
  }

  return { checkoutId: orderData.id as string, url: approveLink.href };
}

function requiredEnv(name: string) {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing ${name}`);
  return value;
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
