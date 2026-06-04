export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: { id: string; email: string; display_name: string | null; role: 'student' | 'admin'; created_at: string }
        Insert: { id: string; email: string; display_name?: string | null; role?: 'student' | 'admin' }
        Update: { email?: string; display_name?: string | null; role?: 'student' | 'admin' }
      }
      resources: {
        Row: { id: string; name: string; type: string; description: string | null; location: string | null; quantity: number; created_at: string }
        Insert: { name: string; type: string; description?: string | null; location?: string | null; quantity?: number }
        Update: { name?: string; type?: string; description?: string | null; location?: string | null; quantity?: number }
      }
      reservations: {
        Row: { id: string; resource_id: string; user_id: string; start_time: string; end_time: string; status: 'pending' | 'confirmed' | 'cancelled'; created_at: string }
        Insert: { resource_id: string; user_id: string; start_time: string; end_time: string; status?: 'pending' | 'confirmed' | 'cancelled' }
        Update: { resource_id?: string; start_time?: string; end_time?: string; status?: 'pending' | 'confirmed' | 'cancelled' }
      }
    }
  }
}
