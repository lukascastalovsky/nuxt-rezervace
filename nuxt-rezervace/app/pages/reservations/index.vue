<script setup lang="ts">
import type { Database } from '~/types/database'
const supabase = useSupabaseClient<Database>()
const user = useSupabaseUser()
const { profile } = useProfile()

type Row = Database['public']['Tables']['reservations']['Row'] & {
  resources: { name: string; type: string } | null
}

const items = ref<Row[]>([])
const loading = ref(true)
const error = ref<string | null>(null)

async function fetchAll() {
  loading.value = true
  let query = supabase
    .from('reservations')
    .select('*, resources(name, type)')
    .order('start_time', { ascending: false })
  if (profile.value?.role !== 'admin' && user.value) {
    query = query.eq('user_id', user.value.id)
  }
  const { data, error: err } = await query
  if (err) error.value = err.message
  else items.value = (data as unknown as Row[]) ?? []
  loading.value = false
}
watchEffect(() => { if (user.value && profile.value !== undefined) fetchAll() })

async function cancel(id: string) {
  if (!confirm('Zrušit rezervaci?')) return
  const { error: err } = await supabase.from('reservations').update({ status: 'cancelled' }).eq('id', id)
  if (err) { error.value = err.message; return }
  await fetchAll()
}
async function remove(id: string) {
  if (!confirm('Smazat rezervaci natrvalo?')) return
  const { error: err } = await supabase.from('reservations').delete().eq('id', id)
  if (err) { error.value = err.message; return }
  await fetchAll()
}
function fmt(s: string) { return new Date(s).toLocaleString('cs-CZ') }
</script>

<template>
  <div>
    <div class="card" style="display:flex; align-items:center">
      <h1 style="margin:0; flex:1">{{ profile?.role === 'admin' ? 'Všechny rezervace' : 'Mé rezervace' }}</h1>
      <NuxtLink to="/reservations/new" class="btn">+ Nová rezervace</NuxtLink>
    </div>

    <p v-if="error" class="error">{{ error }}</p>
    <div v-if="loading" class="card">Načítám…</div>
    <div v-else-if="!items.length" class="card muted">Žádné rezervace.</div>

    <table v-else class="card" style="display:table">
      <thead>
        <tr>
          <th>Zdroj</th><th>Od</th><th>Do</th><th>Stav</th><th></th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="r in items" :key="r.id">
          <td>{{ r.resources?.name }} <span class="badge">{{ r.resources?.type }}</span></td>
          <td>{{ fmt(r.start_time) }}</td>
          <td>{{ fmt(r.end_time) }}</td>
          <td><span class="badge" :class="'status-' + r.status">{{ r.status }}</span></td>
          <td style="text-align:right">
            <button v-if="r.status !== 'cancelled'" class="btn btn-sm btn-secondary" @click="cancel(r.id)">Zrušit</button>
            <button v-if="profile?.role === 'admin'" class="btn btn-sm btn-danger" style="margin-left:0.3rem" @click="remove(r.id)">Smazat</button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
