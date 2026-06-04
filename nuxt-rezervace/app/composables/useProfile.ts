import type { Database } from '~/types/database'

export const useProfile = () => {
  const user = useSupabaseUser()
  const supabase = useSupabaseClient<Database>()
  const profile = useState<Database['public']['Tables']['profiles']['Row'] | null>('profile', () => null)

  watch(user, async (u) => {
    if (!u) { profile.value = null; return }
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', u.id)
      .maybeSingle()
    profile.value = data
  }, { immediate: true })

  return { profile }
}
