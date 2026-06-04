export default defineNuxtConfig({
  compatibilityDate: '2025-01-01',
  future: { compatibilityVersion: 4 },
  modules: ['@nuxtjs/supabase'],
  supabase: {
    redirectOptions: {
      login: '/login',
      callback: '/confirm',
      include: ['/dashboard(/*)?', '/resources(/*)?', '/reservations(/*)?', '/admin(/*)?'],
      exclude: ['/', '/login', '/register'],
    },
  },
  app: {
    head: {
      title: 'Rezervace učeben a vybavení',
      meta: [
        { name: 'description', content: 'Rezervační systém učeben a vybavení postavený na Nuxt 4 a Supabase.' },
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
      ],
    },
  },
  css: ['~/assets/main.css'],
})
