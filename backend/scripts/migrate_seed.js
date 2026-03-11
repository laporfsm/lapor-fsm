import * as fs from 'fs';
import * as path from 'path';

const seedPath = path.join(process.cwd(), 'src/db/seed.ts');
let content = fs.readFileSync(seedPath, 'utf8');

// Replace "assignedTo": null with "assignedTo": [], "handlerNames": null
content = content.replace(/"assignedTo": null,/g, '"assignedTo": [],\n      "handlerNames": null,');

// Replace "assignedTo": 146 with "assignedTo": [146], "handlerNames": "Agus T"
content = content.replace(/"assignedTo": 146,/g, '"assignedTo": [146],\n      "handlerNames": "Agus T",');

// Replace "assignedTo": 147 with "assignedTo": [147], "handlerNames": "Bambang T"
content = content.replace(/"assignedTo": 147,/g, '"assignedTo": [147],\n      "handlerNames": "Bambang T",');

// Replace "assignedTo": 148 with "assignedTo": [148], "handlerNames": "Dodi T"
content = content.replace(/"assignedTo": 148,/g, '"assignedTo": [148],\n      "handlerNames": "Dodi T",');

fs.writeFileSync(seedPath, content, 'utf8');
console.log('seed.ts updated successfully.');
