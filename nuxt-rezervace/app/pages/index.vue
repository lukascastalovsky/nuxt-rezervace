<script setup lang="ts">
const user = useSupabaseUser()
</script>

<template>
  <div>
    <div class="card">
      <h1>Rezervační systém učeben a vybavení</h1>
      <p class="muted">
        Webová aplikace postavená na Nuxt 4 a Supabase. Umožňuje rezervaci učeben,
        laboratoří a vypůjčitelného vybavení s kontrolou kolizí časových oken.
      </p>
      <div style="margin-top: 1rem">
        <NuxtLink v-if="user" to="/resources" class="btn">Procházet zdroje</NuxtLink>
        <template v-else>
          <NuxtLink to="/login" class="btn">Přihlásit se</NuxtLink>
          &nbsp;
          <NuxtLink to="/register" class="btn btn-secondary">Registrovat</NuxtLink>
        </template>
      </div>
    </div>

    <div class="card">
      <h2>Funkce</h2>
      <ul>
        <li>Autentizace přes Supabase Auth (registrace, přihlášení, odhlášení)</li>
        <li>CRUD nad zdroji (učebny, vybavení)</li>
        <li>Filtrování a vyhledávání podle názvu, typu, dostupnosti</li>
        <li>Rezervace s kontrolou kolizí (overlap check)</li>
        <li>Role <code>student</code> a <code>admin</code> (RLS politiky)</li>
      </ul>
    </div>
  </div>
</template>
