const fs = require("fs");
const path = require("path");

const sourceDir = path.resolve(__dirname, "../node_modules", "gargarollotto2");
const targetDir = path.resolve(__dirname, "../node_modules", "@tokenbound", "contracts");

if (!fs.existsSync(path.dirname(targetDir))) {
  fs.mkdirSync(path.dirname(targetDir), {recursive: true});
}

try {
  const linkStats = fs.lstatSync(targetDir);

  if (linkStats.isSymbolicLink()) {
    console.log(`Symlink already exists: ${targetDir}`);
  } else {
    console.log(`Target is not a symlink, will not overwrite: ${targetDir}`);
  }
} catch (err) {
  fs.symlinkSync(sourceDir, targetDir, "junction");
  console.log(`Symlink created: ${targetDir} -> ${sourceDir}`);
}
