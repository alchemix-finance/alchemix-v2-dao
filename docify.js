const NODE_MODULES_DIR = "./node_modules";
const INPUT_DIR = `${process.cwd()}/src`;
const CONFIG_DIR = "./docs";
const OUTPUT_DIR = "./docs/pages";
const HELPER_FILE = "./docs/helpers.js";
const IGNORE_FILE = "./docs/.docignore";
const fs = require("fs");

/*
  here lies a bunch of bullshit pre/post processing we must do.
  we can deprecate this once https://github.com/OpenZeppelin/solidity-docgen releases version 0.6.0 (currently in beta, and doest work)
*/
function getRemappings() {
  return fs
    .readFileSync("remappings.txt", "utf8")
    .split("\n")
    .filter(Boolean) // remove empty lines
    .map((line) => line.trim().split("="));
}

function getReverseMappings() {
  return fs
    .readFileSync("remappings.txt", "utf8")
    .split("\n")
    .filter(Boolean) // remove empty lines
    .map((line) => {
      let keys = line.trim().split("=")
      let newkey = keys.pop()
      keys.unshift(newkey)
      return keys
    });
}

function transform(rawContent, remappings) {
  return rawContent
      .split(/\r?\n/)
      .map((line) => {
          const newLine = doit(line, remappings);
          if (newLine.split(/\r?\n/).length > 1) {
              // prevent lines generated to create more line, this ensure preservation of line number while debugging
              throw new Error(`Line processor cannot create new lines. This ensures that line numbers are preserved`);
          }
          return newLine;
      })
      .join('\n');
}

function doit(line, remappings) {
  if (line.match(/^\s*import /i)) {
    remappings.forEach(([find, replace]) => {
      if (line.match(find)) {
        line = line.replace(find, replace);
      }
    });
  }
  return line;
}

function preprocess(pathName) {
  let content = fs.readFileSync(pathName, { encoding: "utf8" }).toString()
  let newContent = transform(content, getRemappings());
  fs.writeFileSync(pathName, newContent)
}

function postprocess(pathName) {
  let content = fs.readFileSync(pathName, { encoding: "utf8" }).toString()
  let newContent = transform(content, getReverseMappings());
  fs.writeFileSync(pathName, newContent)
}








// preprocess imports
preprocess(`${process.cwd()}/lib/forge-std/src/Test.sol`)

function lines(pathName) {
  return fs.readFileSync(pathName, { encoding: "utf8" }).split("\r").join("").split("\n");
}

// run solidity-docgen
const spawnSync = require("child_process").spawnSync;
const EXCLUDE_DIR_LIST = `${process.cwd()}/src/test`
const args = [
  NODE_MODULES_DIR + "/solidity-docgen/dist/cli.js",
  "--input=" + INPUT_DIR,
  "--output=" + OUTPUT_DIR,
  "--templates=" + CONFIG_DIR,
  "--helpers=" + HELPER_FILE,
  "--exclude=" + EXCLUDE_DIR_LIST,
  "--solc-module=./" + NODE_MODULES_DIR + "/solc",
  "--solc-settings=" + JSON.stringify({ optimizer: { enabled: true, runs: 200 }, remappings: ["forge-std/:lib/forge-std/src/", "openzeppelin-contracts/contracts/:lib/openzeppelin-contracts/contracts/"]}),
];
const result = spawnSync("node", args, {
  stdio: ["inherit", "inherit", "pipe"],
});

// if (result.stderr.length > 0) {
//   throw new Error(result.stderr);
// }


// Delete unused folders and files
const excludeList = lines(IGNORE_FILE).map((line) => INPUT_DIR + "/" + line);
for (let i = 0; i < excludeList.length; i++) {
  let dir = excludeList[i].replace("src", "docs/pages");
  try {
    if (dir.slice(dir.length - 3) === "sol") {
      dir = dir.replace("sol", "md");
    }
    fs.rm(dir, { recursive: true }, () => console.log(`${dir} is deleted!`));
  } catch (err) {
    console.error(`Error while deleting ${dir}.`);
  }
}

// postprocess imports to undo preprocessing
postprocess(`${process.cwd()}/lib/forge-std/src/Test.sol`)