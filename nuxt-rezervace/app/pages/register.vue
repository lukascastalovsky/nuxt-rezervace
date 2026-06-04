<script setup lang="ts">
const supabase = useSupabaseClient()
const email = ref('')
const password = ref('')
const displayName = ref('')
const error = ref<string | null>(null)
const success = ref<string | null>(null)
const loading = ref(false)

async function register() {
  error.value = null; success.value = null
  if (password.value.length < 6) { error.value = 'Heslo musí mít alespoň 6 znaků.'; return }
  loading.value = true
  const { error: err } = await supabase.auth.signUp({
    email: email.value,
    password: password.value,
    options: {
      emailRedirectTo: typeof window !== 'undefined' ? `${window.location.origin}/confirm` : undefined,
      data: { display_name: displayName.value },
    },
  })
  loading.value = false
  if (err) { error.value = err.message; return }
  success.value = 'Účet vytvořen. Pokud je povinné potvrzení e-mailu, zkontrolujte schránku.'
}
</script>

<template>
  <div class="card" style="max-width: 420px; margin: 2rem auto;">
    <h1>Registrace</h1>
    <form @submit.prevent="register">
      <label>Zobrazované jméno</label>
      <input v-model="displayName" required />
      <label>Email</label>
      <input v-model="email" type="email" required />
      <label>Heslo (min. 6 znaků)</label>
      <input v-model="password" type="password" required />
      <p v-if="error" class="error">{{ error }}</p>
      <p v-if="success" class="success">{{ success }}</p>
      <div style="margin-top: 1rem">
        <button class="btn" :disabled="loading">{{ loading ? 'Vytvářím…' : 'Registrovat' }}</button>
      </div>
    </form>
    <p class="muted" style="margin-top: 1rem">
      Máte účet? <NuxtLink to="/login">Přihlášení</NuxtLink>
    </p>
  </div>
</template>
