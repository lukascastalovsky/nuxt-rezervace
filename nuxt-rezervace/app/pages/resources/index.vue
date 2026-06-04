<script setup lang="ts">
import type { Database } from '~/types/database'
const supabase = useSupabaseClient<Database>()
const { profile } = useProfile()

type Resource = Database['public']['Tables']['resources']['Row']

const resources = ref<Resource[]>([])
const loading = ref(true)
const error = ref<string | null>(null)

const search = ref('')
const typeFilter = ref('')
const availabilityFilter = ref<'all' | 'available'>('all')

const showForm = ref(false)
const editing = ref<Resource | null>(null)
const form = reactive({ name: '', type: '', description: '', location: '', quantity: 1 })

async function fetchResources() {
  loading.value = true
  const { data, error: err } = await supabase
    .from('resources')
    .select('*')
    .order('created_at', { ascending: false })
  if (err) error.value = err.message
  else resources.value = data ?? []
  loading.value = false
}
onMounted(fetchResources)

const types = computed(() => Array.from(new Set(resources.value.map(r => r.type))))

const filtered = computed(() => {
  return resources.value.filter(r => {
    if (search.value && !r.name.toLowerCase().includes(search.value.toLowerCase())) return false
    if (typeFilter.value && r.type !== typeFilter.value) return false
    if (availabilityFilter.value === 'available' && r.quantity < 1) return false
    return true
  })
})

function openCreate() {
  editing.value = null
  Object.assign(form, { name: '', type: '', description: '', location: '', quantity: 1 })
  showForm.value = true
}
function openEdit(r: Resource) {
  editing.value = r
  Object.assign(form, {
    name: r.name, type: r.type, description: r.description ?? '',
    location: r.location ?? '', quantity: r.quantity,
  })
  showForm.value = true
}

async function save() {
  error.value = null
  if (!form.name.trim() || !form.type.trim()) {
    error.value = 'Název a typ jsou povinné.'; return
  }
  if (form.quantity < 0) { error.value = 'Množství musí být ≥ 0.'; return }

  if (editing.value) {
    const { error: err } = await supabase.from('resources').update({
      name: form.name, type: form.type, description: form.description || null,
      location: form.location || null, quantity: form.quantity,
    }).eq('id', editing.value.id)
    if (err) { error.value = err.message; return }
  } else {
    const { error: err } = await supabase.from('resources').insert({
      name: form.name, type: form.type, description: form.description || null,
      location: form.location || null, quantity: form.quantity,
    })
    if (err) { error.value = err.message; return }
  }
  showForm.value = false
  await fetchResources()
}

async function remove(r: Resource) {
  if (!confirm(`Opravdu smazat „${r.name}"? Tato akce je nevratná.`)) return
  const { error: err } = await supabase.from('resources').delete().eq('id', r.id)
  if (err) { error.value = err.message; return }
  await fetchResources()
}
</script>

<template>
  <div>
    <div class="card">
      <div style="display:flex; align-items:center; gap:1rem">
        <h1 style="margin:0; flex:1">Zdroje</h1>
        <button v-if="profile?.role === 'admin'" class="btn" @click="openCreate">+ Nový zdroj</button>
      </div>
      <div class="row" style="margin-top: 1rem">
        <input v-model="search" placeholder="Hledat podle názvu…" />
        <select v-model="typeFilter">
          <option value="">Všechny typy</option>
          <option v-for="t in types" :key="t" :value="t">{{ t }}</option>
        </select>
        <select v-model="availabilityFilter">
          <option value="all">Všechny</option>
          <option value="available">Pouze dostupné</option>
        </select>
      </div>
    </div>

    <div v-if="showForm" class="card">
      <h2>{{ editing ? 'Upravit zdroj' : 'Nový zdroj' }}</h2>
      <form @submit.prevent="save">
        <div class="row">
          <div><label>Název *</label><input v-model="form.name" required /></div>
          <div><label>Typ *</label><input v-model="form.type" placeholder="učebna / notebook / projektor…" required /></div>
        </div>
        <div class="row">
          <div><label>Umístění</label><input v-model="form.location" /></div>
          <div><label>Množství</label><input v-model.number="form.quantity" type="number" min="0" /></div>
        </div>
        <label>Popis</label>
        <textarea v-model="form.description" rows="3"></textarea>
        <p v-if="error" class="error">{{ error }}</p>
        <div style="margin-top:1rem; display:flex; gap:0.5rem">
          <button class="btn" type="submit">Uložit</button>
          <button class="btn btn-secondary" type="button" @click="showForm = false">Zrušit</button>
        </div>
      </form>
    </div>

    <div v-if="loading" class="card">Načítám…</div>
    <div v-else-if="!filtered.length" class="card muted">Žádné zdroje neodpovídají filtru.</div>

    <div v-for="r in filtered" :key="r.id" class="card">
      <div style="display:flex; gap:1rem; align-items:flex-start">
        <div style="flex:1">
          <h3 style="margin:0 0 0.25rem 0">{{ r.name }} <span class="badge">{{ r.type }}</span></h3>
          <div class="muted">{{ r.location || '—' }} · k dispozici: {{ r.quantity }}</div>
          <p v-if="r.description" style="margin:0.5rem 0 0">{{ r.description }}</p>
        </div>
        <div style="display:flex; flex-direction:column; gap:0.4rem">
          <NuxtLink :to="`/reservations/new?resource=${r.id}`" class="btn btn-sm">Rezervovat</NuxtLink>
          <template v-if="profile?.role === 'admin'">
            <button class="btn btn-sm btn-secondary" @click="openEdit(r)">Upravit</button>
            <button class="btn btn-sm btn-danger" @click="remove(r)">Smazat</button>
          </template>
        </div>
      </div>
    </div>
  </div>
</template>
