const fs = require('fs');
const path = require('path');
const { testGroqConnection } = require('./test-groq-connection');

// Load environment variables from backend/.env file
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const { Groq } = require('groq-sdk');

// Add debug mode flag
const DEBUG = process.env.DEBUG === 'true';

/**
 * Debug logger
 * @param {...any} args - Arguments to log
 */
function debug(...args) {
    if (DEBUG) {
        console.log('🔍 [DEBUG]', ...args);
    }
}

// Type definitions for type safety
/**
 * @typedef {Object} SarifResult
 * @property {string} ruleId
 * @property {number} ruleIndex
 * @property {Object} message
 * @property {Object[]} locations
 * @property {Object} partialFingerprints
 */

/**
 * @typedef {Object} IssueInfo
 * @property {string} ruleId
 * @property {string} message
 * @property {string} filePath
 * @property {number} line
 * @property {number} column
 * @property {string} ruleName
 * @property {string} severity
 */

/**
 * @typedef {Object} GroqResponse
 * @property {Object[]} choices
 * @property {Object} choices[].message
 * @property {string} choices[].message.content
 */

// Initialize Groq client
const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY || ''
});

/**
 * Parse SARIF file and extract issues
 * @param {string} sarifPath - Path to the SARIF file
 * @returns {IssueInfo[]} Array of extracted issues
 */
function parseSarifFile(sarifPath) {
  const sarifContent = fs.readFileSync(sarifPath, 'utf-8');
  const sarifData = JSON.parse(sarifContent);
  
  const issues = [];
  
  if (sarifData.runs && sarifData.runs.length > 0) {
    const run = sarifData.runs[0];
    
    // Get rules mapping for rule details
    const rulesMap = {};
    if (run.tool && run.tool.driver && run.tool.driver.rules) {
      run.tool.driver.rules.forEach((rule, index) => {
        rulesMap[rule.id] = {
          name: rule.name || rule.id,
          shortDescription: rule.shortDescription?.text || '',
          fullDescription: rule.fullDescription?.text || '',
          severity: rule.defaultConfiguration?.level || 'warning',
          properties: rule.properties || {}
        };
      });
    }
    
    // Process results
    if (run.results && run.results.length > 0) {
      run.results.forEach((result) => {
        const location = result.locations && result.locations[0];
        if (!location) return;
        
        const physicalLocation = location.physicalLocation;
        const artifactLocation = physicalLocation?.artifactLocation;
        const region = physicalLocation?.region;
        
        if (!artifactLocation || !region) return;
        
        const ruleInfo = rulesMap[result.ruleId] || {};
        
        const issue = {
          ruleId: result.ruleId,
          message: result.message?.text || 'No message available',
          filePath: artifactLocation.uri || '',
          line: region.startLine || 0,
          column: region.startColumn || 0,
          ruleName: ruleInfo.name || result.ruleId,
          severity: ruleInfo.severity || 'warning',
          description: ruleInfo.fullDescription || ruleInfo.shortDescription || '',
          securitySeverity: ruleInfo.properties?.['security-severity'] || ''
        };
        
        issues.push(issue);
      });
    }
  }
  
  return issues;
}

/**
 * Generate fix prompt using Groq API
 * @param {IssueInfo} issue - The issue to generate a fix for
 * @param {string} codeContext - The relevant code context around the issue
 * @returns {Promise<string>} Generated fix prompt
 */
async function generateFixPrompt(issue, codeContext) {
  const prompt = `You are a senior software engineer reviewing a CodeQL security/safety issue.

**Issue Details:**
- Rule ID: ${issue.ruleId}
- Rule Name: ${issue.ruleName}
- Severity: ${issue.severity}
- File: ${issue.filePath}
- Line: ${issue.line}, Column: ${issue.column}
- Message: ${issue.message}
${issue.description ? `- Description: ${issue.description}` : ''}
${issue.securitySeverity ? `- Security Severity: ${issue.securitySeverity}` : ''}

**Code Context:**
\`\`\`javascript
${codeContext}
\`\`\`

**Task:**
Generate a comprehensive fix guide in markdown format that includes:
1. A clear explanation of the issue
2. Why this is a problem (security/quality implications)
3. Step-by-step fix instructions
4. The corrected code (with proper syntax highlighting)
5. Best practices to prevent similar issues
6. Testing recommendations

Be specific, actionable, and provide production-ready code fixes.`;

  try {
    const completion = await groq.chat.completions.create({
      messages: [
        {
          role: 'system',
          content: 'You are an expert JavaScript/TypeScript security engineer specializing in code quality and security vulnerabilities. Provide detailed, actionable fix guidance.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      model: 'llama-3.1-8b-instant',
      temperature: 0.3,
      max_tokens: 2000
    });

    return completion.choices[0]?.message?.content || 'Failed to generate fix prompt';
  } catch (error) {
    console.error(`Error calling Groq API for issue ${issue.ruleId}:`, error.message);
    return `# Fix Guide for ${issue.ruleName}

**Error:** Failed to generate fix prompt via Groq API: ${error.message}

**Issue Details:**
- Rule ID: ${issue.ruleId}
- File: ${issue.filePath}
- Line: ${issue.line}
- Message: ${issue.message}

Please review the code manually and apply appropriate fixes.`;
  }
}

/**
 * Read code context around the issue location
 * @param {string} filePath - Path to the file with the issue
 * @param {number} line - Line number of the issue
 * @param {number} contextLines - Number of lines before and after to include
 * @param {string} sarifBasePath - Base path where SARIF file is located (for resolving relative paths)
 * @returns {string} Code context
 */
function getCodeContext(filePath, line, contextLines = 10, sarifBasePath = null) {
  try {
    // Handle relative paths from SARIF
    let fullPath = filePath;
    
    // Remove URI base ID prefixes like %SRCROOT%
    if (filePath.includes('%SRCROOT%')) {
      filePath = filePath.replace('%SRCROOT%/', '');
    }
    
    // If not absolute, try to resolve relative paths
    if (!path.isAbsolute(filePath)) {
      const possiblePaths = [];
      
      // If SARIF base path is provided, try relative to that
      if (sarifBasePath) {
        const sarifDir = path.dirname(sarifBasePath);
        possiblePaths.push(
          path.join(sarifDir, filePath),
          path.resolve(sarifDir, filePath)
        );
      }
      
      // Try relative to current working directory
      possiblePaths.push(
        path.join(process.cwd(), filePath),
        path.resolve(process.cwd(), filePath),
        path.join(process.cwd(), 'src', filePath),
        path.resolve(process.cwd(), 'src', filePath)
      );
      
      // Try as absolute path if it looks like a full path
      if (filePath.startsWith('/') || /^[A-Z]:/.test(filePath)) {
        possiblePaths.push(filePath);
      }
      
      // Try each possible path
      for (const possiblePath of possiblePaths) {
        try {
          if (fs.existsSync(possiblePath)) {
            fullPath = possiblePath;
            break;
          }
        } catch (e) {
          // Continue to next path
        }
      }
    } else {
      fullPath = filePath;
    }
    
    // Normalize the path
    fullPath = path.normalize(fullPath);
    
    if (!fs.existsSync(fullPath)) {
      return `File not found: ${filePath}\nTried: ${fullPath}`;
    }
    
    const content = fs.readFileSync(fullPath, 'utf-8');
    const lines = content.split('\n');
    
    const startLine = Math.max(0, line - contextLines - 1);
    const endLine = Math.min(lines.length, line + contextLines);
    
    const context = lines.slice(startLine, endLine);
    const lineNumbers = context.map((_, idx) => {
      const lineNum = startLine + idx + 1;
      const marker = lineNum === line ? ' >>> ' : '     ';
      return `${marker}${lineNum.toString().padStart(4, ' ')} | ${lines[startLine + idx]}`;
    }).join('\n');
    
    return lineNumbers;
  } catch (error) {
    return `Error reading file: ${error.message}`;
  }
}

/**
 * Sanitize filename for safe file system usage
 * @param {string} filename - Original filename
 * @returns {string} Sanitized filename
 */
function sanitizeFilename(filename) {
  return filename
    .replace(/[^a-z0-9]/gi, '_')
    .replace(/_+/g, '_')
    .toLowerCase()
    .substring(0, 100);
}

/**
 * Parse command-line arguments
 * @returns {{sarifPath: string, outputDir: string}}
 */
function parseArguments() {
  const args = process.argv.slice(2);
  
  let sarifPath = null;
  let outputDir = null;
  
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    
    if (arg === '--help' || arg === '-h') {
      console.log(`
Usage: node process-sarif.js [options] <sarif-file>

Arguments:
  <sarif-file>              Path to the SARIF file (required)

Options:
  -o, --output <dir>       Output directory for fix guides (default: ./fixcode)
  -h, --help               Show this help message

Examples:
  node process-sarif.js results.sarif
  node process-sarif.js /path/to/results.sarif
  node process-sarif.js results.sarif -o ./fixes
  node process-sarif.js C:\\Users\\project\\results.sarif -o C:\\output
`);
      process.exit(0);
    } else if (arg === '--output' || arg === '-o') {
      if (i + 1 < args.length) {
        outputDir = args[++i];
      } else {
        console.error('❌ Error: --output requires a directory path');
        process.exit(1);
      }
    } else if (!sarifPath && !arg.startsWith('-')) {
      sarifPath = arg;
    }
  }
  
  // If no SARIF path provided, try default
  if (!sarifPath) {
    const defaultPath = path.join(process.cwd(), 'results.sarif');
    if (fs.existsSync(defaultPath)) {
      sarifPath = defaultPath;
      console.log(`ℹ️  No SARIF file specified, using default: ${sarifPath}`);
    } else {
      console.error('❌ Error: SARIF file path is required');
      console.log('Usage: node process-sarif.js <sarif-file> [options]');
      console.log('Use --help for more information');
      process.exit(1);
    }
  }
  
  // Resolve paths to absolute
  sarifPath = path.resolve(sarifPath);
  outputDir = outputDir ? path.resolve(outputDir) : path.join(path.dirname(sarifPath), 'fixcode');
  
  return { sarifPath, outputDir };
}

/**
 * Process a SARIF file and generate fix guides
 * @param {string} sarifPath
 * @param {string} outputDir
 */
async function processSarif(sarifPath, outputDir) {
  // Parse command-line arguments
  sarifPath = path.resolve(sarifPath);
  outputDir = outputDir ? path.resolve(outputDir) : path.join(path.dirname(sarifPath), 'fixcode');
  
  // Check if GROQ_API_KEY is set
  if (!process.env.GROQ_API_KEY) {
    console.error('❌ Error: GROQ_API_KEY environment variable is not set.');
    console.log('\nPlease set it using one of these methods:');
    console.log('1. Create a .env file in the project root with:');
    console.log('   GROQ_API_KEY=your_api_key_here');
    console.log('\n2. Or set it as an environment variable:');
    console.log('   Windows PowerShell: $env:GROQ_API_KEY="your_api_key"');
    console.log('   Windows CMD: set GROQ_API_KEY=your_api_key');
    console.log('   Linux/Mac: export GROQ_API_KEY="your_api_key"');
    process.exit(1);
  }
  
  // Check if SARIF file exists
  if (!fs.existsSync(sarifPath)) {
    console.error(`❌ Error: SARIF file not found at ${sarifPath}`);
    process.exit(1);
  }
  
  // Validate it's a file, not a directory
  const stats = fs.statSync(sarifPath);
  if (!stats.isFile()) {
    console.error(`❌ Error: ${sarifPath} is not a file`);
    process.exit(1);
  }
  
  // Create output directory
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
    console.log(`✅ Created output directory: ${outputDir}`);
  }
  
  console.log(`📖 Processing SARIF file: ${sarifPath}`);
  console.log(`📁 Output directory: ${outputDir}\n`);
  
  const issues = parseSarifFile(sarifPath);
  console.log(`✅ Found ${issues.length} issues\n`);
  
  if (issues.length === 0) {
    console.log('No issues found in SARIF file.');
    return;
  }
  
  // Get SARIF base path for resolving relative file paths
  const sarifBasePath = path.dirname(sarifPath);
  
  // Process each issue
  for (let i = 0; i < issues.length; i++) {
    const issue = issues[i];
    console.log(`\n[${i + 1}/${issues.length}] Processing: ${issue.ruleName}`);
    console.log(`   File: ${issue.filePath}:${issue.line}`);
    
    // Get code context (pass SARIF base path for better path resolution)
    const codeContext = getCodeContext(issue.filePath, issue.line, 10, sarifPath);
    
    // Generate fix prompt
    console.log(`   Generating fix prompt via Groq API...`);
    const fixPrompt = await generateFixPrompt(issue, codeContext);
    
    // Create markdown content
    const markdownContent = `# Fix Guide: ${issue.ruleName}

**Generated:** ${new Date().toISOString()}

## Issue Summary

| Property | Value |
|----------|-------|
| **Rule ID** | \`${issue.ruleId}\` |
| **Rule Name** | ${issue.ruleName} |
| **Severity** | ${issue.severity} |
| **File** | \`${issue.filePath}\` |
| **Location** | Line ${issue.line}, Column ${issue.column} |
| **Message** | ${issue.message} |
${issue.securitySeverity ? `| **Security Severity** | ${issue.securitySeverity} |` : ''}

${issue.description ? `## Description\n\n${issue.description}\n\n` : ''}

---

## AI-Generated Fix Guide

${fixPrompt}

---

## Code Context

\`\`\`javascript
${codeContext}
\`\`\`

---

*This fix guide was automatically generated from CodeQL analysis results.*
`;
    
    // Save to file
    const filename = `${i + 1}_${sanitizeFilename(issue.ruleId)}_${sanitizeFilename(issue.ruleName)}.md`;
    const outputFilePath = path.join(outputDir, filename);
    
    fs.writeFileSync(outputFilePath, markdownContent, 'utf-8');
    console.log(`   ✅ Saved: ${filename}`);
    
    // Add small delay to avoid rate limiting
    if (i < issues.length - 1) {
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
  }
  
  console.log(`\n✅ Done! Generated ${issues.length} fix guides in ${outputDir}`);
}

// Run the script
if (require.main === module) {
  (async () => {
    const { sarifPath, outputDir } = parseArguments();
    await processSarif(sarifPath, outputDir);
  })().catch(error => {
    console.error('❌ Fatal error:', error);
    process.exit(1);
  });
}

module.exports = { parseSarifFile, generateFixPrompt, getCodeContext, processSarif };

