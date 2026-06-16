import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

// Initialize the edge function
serve(async (req) => {
  // CORS headers
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers })
  }

  try {
    const { transcript } = await req.json()

    if (!transcript) {
      return new Response(JSON.stringify({ error: 'No transcript provided' }), {
        status: 400,
        headers: { ...headers, 'Content-Type': 'application/json' },
      })
    }

    // Get the Gemini API Key from Supabase Secrets
    const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')

    if (!GEMINI_API_KEY) {
      return new Response(JSON.stringify({ error: 'GEMINI_API_KEY is not set in Edge Function secrets' }), {
        status: 500,
        headers: { ...headers, 'Content-Type': 'application/json' },
      })
    }

    const prompt = `
Anda adalah asisten pencatat keuangan pintar.
Tugas Anda adalah mengekstrak informasi transaksi dari kalimat berikut dan mengembalikannya HANYA dalam format JSON yang valid tanpa markdown tambahan.

Aturan Kategori Pengeluaran: Konsumsi & Belanja, Tagihan & Kewajiban, Transportasi, Gaya Hidup, Kesehatan & Edukasi, Lainnya.
Aturan Kategori Pemasukan: Penghasilan Utama, Penghasilan Tambahan, Investasi & Lainnya.

Kalimat: "${transcript}"

Format Output JSON yang diharapkan:
{
  "type": "expense", // atau "income"
  "amount": 50000, // angka nominal
  "categoryName": "Konsumsi & Belanja", // pilih dari daftar di atas yang paling cocok
  "description": "Beli jajan" // ringkasan singkat
}
`

    // Call Google Gemini REST API
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`
    
    const geminiResponse = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.2,
        }
      })
    })

    const geminiData = await geminiResponse.json()
    const textResult = geminiData.candidates?.[0]?.content?.parts?.[0]?.text

    if (!textResult) {
      throw new Error('Failed to parse response from Gemini')
    }

    // Clean JSON markdown blocks if any
    const cleanJson = textResult.replace(/```json/g, '').replace(/```/g, '').trim()
    const parsedData = JSON.parse(cleanJson)

    return new Response(JSON.stringify(parsedData), {
      status: 200,
      headers: { ...headers, 'Content-Type': 'application/json' },
    })
    
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...headers, 'Content-Type': 'application/json' },
    })
  }
})
