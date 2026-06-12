import { createClient } from 'npm:@supabase/supabase-js'

const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

Deno.serve(async (req) => {
  const { provider, providerId, email } = await req.json()

  const { data, error } = await supabaseAdmin.auth.admin.listUsers()

if (error) {
  return new Response(JSON.stringify({ error }), { status: 500 })
}

const user = data.users.find((u) => u.email === email)

if (user) {
  await supabaseAdmin.from('user_identities').insert({
    user_id: user.id,
    provider,
    provider_id: providerId,
  })
  return new Response(JSON.stringify({ user }), { status: 200 })
}

return new Response(JSON.stringify({ message: 'No existing user' }), { status: 200 })

})
