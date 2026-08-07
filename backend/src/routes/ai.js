const express = require('express');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.post('/advice', requireAuth, async (req, res) => {
  try {
    const { topic } = req.body || {};
    if (!topic) return res.status(400).json({ error: 'topic is required' });

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return res.status(503).json({ error: 'AI advisor is not configured on the server (missing GEMINI_API_KEY)' });
    }

    const prompt = `You are a concise stock market mentor.
Explain clearly with bullet points and simple examples.
Use INR context and Indian stock market.
Keep sections: Overview, Key Concepts, Practical Tips.

Create an easy-to-follow guide on ${topic} for a beginner trader in India.
Keep it under 300 words. Include 3 do's and 3 don'ts.`;

    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=${apiKey}`;
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.4, maxOutputTokens: 600 },
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error('Gemini error:', errText);
      return res.status(502).json({ error: 'AI advisor request failed' });
    }

    const data = await response.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || '';
    res.json({ content: text });
  } catch (err) {
    console.error('AI advice error:', err);
    res.status(500).json({ error: 'AI advisor request failed' });
  }
});

module.exports = router;
