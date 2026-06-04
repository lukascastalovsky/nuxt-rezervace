<script setup lang="ts">
import type { Database } from '~/types/database'
const supabase = useSupabaseClient<Database>()
const user = useSupabaseUser()
const route = useRoute()

type Resource = Database['public']['Tables']['resources']['Row']

const resources = ref<Resource[]>([])
const form = reactive({
  resource_id: (route.query.resource as string) || '',
  start_time: '',
  end_time: '',
})
const error = ref<string | null>(null)
const submitting = ref(false)

onMounted(async () => {
  const { data } = await supabase.from('resources').select('*').order('name')
  resources.value = data ?? []
})

async function submit() {
  error.value = null
  if (!form.resource_id) { error.value = 'Vyberte zdroj.'; return }
  if (!form.start_time || !form.end_time) { error.value = 'Vyplňte časy.'; return }
  const start = new Date(form.start_time)
  const end = new Date(form.end_time)
  if (!(start < end)) { error.value = 'Začátek musí být před koncem.'; return }
  if (start < new Date()) { error.value = 'Nelze rezervovat v minulosti.'; return }

  submitting.value = true

  // Kolizní kontrola: existuje aktivní rezervace, která se překrývá?
  // Překryv: existing.start < new.end AND existing.end > new.start
  const { data: collisions, error: cErr } = await supabase
    .from('reservations')
    .select('id')
    .eq('resource_id', form.resource_id)
    .neq('status', 'cancelled')
    .lt('start_time', end.toISOString())
    .gt('end_time', start.toISOString())

  if (cErr) { submitting.value = false; error.value = cErr.message; return }
  if (collisions && collisions.length > 0) {
    submitting.value = false
    error.value = 'Zdroj je v daném čase již rezervovaný (kolize).'
    return
  }

  const { error: iErr } = await supabase.from('reservations').insert({
    resource_id: form.resource_id,
    user_id: user.value!.id,
    start_time: start.toISOString(),
    end_time: end.toISOString(),
    status: 'confirmed',
  })
  submitting.value = false
  if (iErr) { error.value = iErr.message; return }
  await navigateTo('/reservations')
}
</script>

<template>
  <div class="card" style="max-width: 560px; margin: 0 auto">
    <h1>Nová rezervace</h1>
    <form @submit.prevent="submit">
      <label>Zdroj *</label>
      <select v-model="form.resource_id" required>
        <option value="">— vyberte —</option>
        <option v-for="r in resources" :key="r.id" :value="r.id">{{ r.name }} ({{ r.type }})</option>
      </select>
      <div class="row">
        <div><label>Od *</label><input v-model="form.start_time" type="datetime-local" required /></div>
        <div><label>Do *</label><input v-model="form.end_time" type="datetime-local" required /></div>
      </div>
      <p v-if="error" class="error">{{ error }}</p>
      <div style="margin-top: 1rem; display:flex; gap:0.5rem">
        <button class="btn" :disabled="submitting">{{ submitting ? 'Ukládám…' : 'Vytvořit rezervaci' }}</button>
        <NuxtLink to="/reservations" class="btn btn-secondary">Zpět</NuxtLink>
      </div>
    </form>
  </div>
</template>
