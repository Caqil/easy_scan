import express from 'express';
import multer from 'multer';
import { exec } from 'child_process';
import fs from 'fs/promises'; // Use promises for async file operations
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const port = 3000;

// Configure multer for file uploads
const upload = multer({ dest: 'uploads/' });

// Supported formats mapping to LibreOffice convert-to options
const formatMap = {
  pdf: 'pdf',
  word: 'docx',
  excel: 'xlsx',
  ppt: 'pptx',
  txt: 'txt',
  image: 'jpg', // Note: LibreOffice converts to PDF, not directly to image
};

app.post('/convert', upload.single('file'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file uploaded' });
  }

  const { sourceFormat, targetFormat } = req.body;
  if (!sourceFormat || !targetFormat) {
    return res.status(400).json({ error: 'sourceFormat and targetFormat are required' });
  }

  const inputFile = req.file.path;
  const outputDir = path.join(__dirname, 'converted');
  const outputExt = formatMap[targetFormat.toLowerCase()] || 'pdf';
  const outputFile = path.join(
    outputDir,
    `${path.basename(inputFile, path.extname(inputFile))}.${outputExt}`
  );

  // Ensure output directory exists
  await fs.mkdir(outputDir, { recursive: true });

  // Build LibreOffice command
  const command = `libreoffice --headless --convert-to ${outputExt} --outdir "${outputDir}" "${inputFile}"`;

  exec(command, async (error, stdout, stderr) => {
    if (error) {
      console.error('Conversion error:', stderr);
      return res.status(500).json({ error: stderr || 'Conversion failed' });
    }

    try {
      // Check if the output file exists
      await fs.access(outputFile);

      // Set headers for file download
      res.setHeader('Content-Type', `application/${outputExt === 'pdf' ? 'pdf' : 'octet-stream'}`);
      res.setHeader('Content-Disposition', `attachment; filename="${path.basename(outputFile)}"`);
      
      // Stream the file to the client
      fs.createReadStream(outputFile).pipe(res);

      // Clean up temporary files
      await fs.unlink(inputFile); // Remove uploaded file
      await fs.unlink(outputFile); // Remove converted file
    } catch (err) {
      res.status(500).json({ error: 'Failed to send file: ' + err.message });
    }
  });
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});