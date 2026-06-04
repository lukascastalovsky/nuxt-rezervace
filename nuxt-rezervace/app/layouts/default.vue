<script setup lang="ts">
const user = useSupabaseUser()
const supabase = useSupabaseClient()
const { profile } = useProfile()

async function logout() {
  await supabase.auth.signOut()
  await navigateTo('/login')
}
</script>

<template>
  <div>
    <nav class="nav">
      <NuxtLink to="/">Rezervace</NuxtLink>
      <NuxtLink v-if="user" to="/resources">Zdroje</NuxtLink>
      <NuxtLink v-if="user" to="/reservations">Mé rezervace</NuxtLink>
      <NuxtLink v-if="profile?.role === 'admin'" to="/admin">Admin</NuxtLink>
      <div class="spacer" />
      <template v-if="user">
        <span class="muted">{{ profile?.display_name || user.email }}</span>
        <span v-if="profile?.role === 'admin'" class="badge role-admin">admin</span>
        <button class="btn btn-sm btn-secondary" @click="logout">Odhlásit</button>
      </template>
      <template v-else>
        <NuxtLink to="/login" class="btn btn-sm">Přihlásit</NuxtLink>
        <NuxtLink to="/register" class="btn btn-sm btn-secondary">Registrace</NuxtLink>
      </template>
    </nav>
    <main class="container">
      <slot />
    </main>
  </div>
</template>
