const { Groq } = require('groq-sdk');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

async function testGroqConnection() {
    console.log('Testing Groq API connection...');
    
    if (!process.env.GROQ_API_KEY) {
        console.error('❌ Error: GROQ_API_KEY not found in environment variables');
        return false;
    }

    const groq = new Groq({
        apiKey: process.env.GROQ_API_KEY
    });

    try {
        const completion = await groq.chat.completions.create({
            messages: [
                {
                    role: 'user',
                    content: 'Hello, this is a test message.'
                }
            ],
            model: 'llama-3.1-8b-instant',
            temperature: 0.3,
            max_tokens: 100
        });

        if (completion.choices && completion.choices[0]?.message?.content) {
            console.log('✅ Groq API connection successful!');
            console.log('Response:', completion.choices[0].message.content);
            return true;
        } else {
            console.error('❌ Error: Unexpected API response format');
            return false;
        }
    } catch (error) {
        console.error('❌ Error connecting to Groq API:', error.message);
        return false;
    }
}

// Run the test if this file is run directly
if (require.main === module) {
    testGroqConnection().catch(console.error);
}

module.exports = { testGroqConnection };