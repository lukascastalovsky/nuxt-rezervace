<script setup lang="ts">
import type { Database } from '~/types/database'
const supabase = useSupabaseClient<Database>()
const { profile } = useProfile()

const users = ref<Database['public']['Tables']['profiles']['Row'][]>([])
const error = ref<string | null>(null)

async function load() {
  const { data, error: err } = await supabase.from('profiles').select('*').order('created_at')
  if (err) error.value = err.message
  else users.value = data ?? []
}
onMounted(load)

async function setRole(id: string, role: 'student' | 'admin') {
  const { error: err } = await supabase.from('profiles').update({ role }).eq('id', id)
  if (err) { error.value = err.message; return }
  await load()
}
</script>

<template>
  <div>
    <div v-if="profile && profile.role !== 'admin'" class="card error">
      Přístup odepřen — pouze administrátoři.
    </div>
    <template v-else>
      <div class="card"><h1>Správa uživatelů</h1></div>
      <p v-if="error" class="error">{{ error }}</p>
      <table class="card" style="display:table">
        <thead><tr><th>Email</th><th>Jméno</th><th>Role</th><th></th></tr></thead>
        <tbody>
          <tr v-for="u in users" :key="u.id">
            <td>{{ u.email }}</td>
            <td>{{ u.display_name || '—' }}</td>
            <td><span class="badge" :class="u.role === 'admin' ? 'role-admin' : ''">{{ u.role }}</span></td>
            <td style="text-align:right">
              <button v-if="u.role !== 'admin'" class="btn btn-sm" @click="setRole(u.id, 'admin')">Povýšit na admina</button>
              <button v-else class="btn btn-sm btn-secondary" @click="setRole(u.id, 'student')">Degradovat</button>
            </td>
          </tr>
        </tbody>
      </table>
    </template>
  </div>
</template>
