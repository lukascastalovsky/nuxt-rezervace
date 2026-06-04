<script setup lang="ts">
definePageMeta({ layout: 'default' })
const supabase = useSupabaseClient()
const email = ref('')
const password = ref('')
const error = ref<string | null>(null)
const loading = ref(false)

async function login() {
  error.value = null; loading.value = true
  const { error: err } = await supabase.auth.signInWithPassword({
    email: email.value, password: password.value,
  })
  loading.value = false
  if (err) { error.value = err.message; return }
  await navigateTo('/resources')
}
</script>

<template>
  <div class="card" style="max-width: 420px; margin: 2rem auto;">
    <h1>Přihlášení</h1>
    <form @submit.prevent="login">
      <label>Email</label>
      <input v-model="email" type="email" required autocomplete="email" />
      <label>Heslo</label>
      <input v-model="password" type="password" required autocomplete="current-password" />
      <p v-if="error" class="error">{{ error }}</p>
      <div style="margin-top: 1rem">
        <button class="btn" :disabled="loading">{{ loading ? 'Přihlašuji…' : 'Přihlásit se' }}</button>
      </div>
    </form>
    <p class="muted" style="margin-top: 1rem">
      Nemáte účet? <NuxtLink to="/register">Registrace</NuxtLink>
    </p>
  </div>
</template>
