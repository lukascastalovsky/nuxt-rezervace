<script setup lang="ts">
const user = useSupabaseUser()
watchEffect(() => { if (user.value) navigateTo('/resources') })
</script>
<template>
  <div class="card" style="text-align:center">Probíhá přihlášení…</div>
</template>
