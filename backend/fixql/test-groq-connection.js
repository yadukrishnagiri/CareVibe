const { Groq } = require('groq-sdk');

/**
 * Simple utility to verify that the Groq API key works.
 * Tries to list the available models. Throws if the request fails.
 *
 * @param {string} [apiKey] - Optional API key override. Defaults to process.env.GROQ_API_KEY.
 * @returns {Promise<{ success: boolean, models: string[] }>}
 */
async function testGroqConnection(apiKey = process.env.GROQ_API_KEY) {
  if (!apiKey) {
    throw new Error('GROQ_API_KEY is not set.');
  }

  const groq = new Groq({ apiKey });

  const response = await groq.models.list();
  const modelNames = Array.isArray(response?.data)
    ? response.data.map((model) => model?.id).filter(Boolean)
    : [];

  return {
    success: true,
    models: modelNames
  };
}

module.exports = { testGroqConnection };



