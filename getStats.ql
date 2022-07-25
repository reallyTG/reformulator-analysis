import javascript
bindingset[filepath]
predicate isTestDir(string filepath) {
 	filepath.matches("%EvalProjects%tests%") or
  	filepath.matches("%EvalProjects%mocks%") or
  	filepath.matches("%EvalProjects%init%") or
  	filepath.matches("%EvalProjects%config%") or
  	filepath.matches("%EvalProjects%docs%") or
  	filepath.matches("%EvalProjects%gulpfile%") or
  	filepath.matches("%EvalProjects%grunt%") or
  	filepath.matches("%EvalProjects%gulp%") or
  	filepath.matches("%EvalProjects%test%") or
  	filepath.matches("%EvalProjects%mock%") or
  	filepath.matches("%EvalProjects%dist%") or
  	filepath.matches("%EvalProjects%.tmp%") or
  	filepath.matches("%EvalProjects%bin%") 
}
bindingset[filename]
predicate isTestFile(string filename) {
 	filename.matches("%EvalProjects%spec.%") or
  	filename.matches("%EvalProjects%mocha.%") or
  	filename.matches("%EvalProjects%test.%") or
  	filename.matches("%EvalProjects%mock.%") or
  	filename.matches("%EvalProjects%conf.%") or
  	filename.matches("%EvalProjects%gruntfile.%") or
  	filename.matches("%EvalProjects%gulpfile.%") or
  	filename.matches("%EvalProjects%webpack.%") 
}
class SourceFile extends File {
	SourceFile() {
      not ( 
        isTestDir(this.getAbsolutePath().toLowerCase()) or 
        isTestFile(getAbsolutePath().toLowerCase())
      )
  	}
}
bindingset[functionName]
predicate isSynchronousFctName(string functionName) {
    functionName in [
        "readFileSync", 
        "writeFileSync", 
        "readdirSync", 
        "accessSync", 
        "appendFileSync", 
        "chmodSync",
        "fchmodSync", 
        "lchmodSync",
        "chownSync",
        "fchownSync",
        "lchownSync", 
        "mkdirSync", 
        "mkdtempSync",
        "statSync", 
        "lstatSync",
        "fstatSync",
        "linkSync",
        "symlinkSync",
        "readlinkSync",
        "realpathSync",
        "unlinkSync",
        "rmdirSync",
        "renameSync", 
        "openSync",
        "closeSync",
        "existsSync", 
        "copyFileSync",
        "truncateSync",
        "ftruncateSync",
        "utimesSync",
        "futimesSync",
        "fsyncSync",
        "writeSync",
        "readSync",
        "fdatasyncSync",
        "gzipSync", 
        "gunzipSync", 
        "brotliCompressSync",
        "brotliDecompressSync", 
        "deflateSync",
        "inflateSync", 
        "deflateRawSync",
        "inflateRawSync", 
        "unzipSync",
        "execSync",
        "spawnSync",
        "execFileSync",
        "pbkdf2Sync", 
        "generateKeyPairSync",
        "randomFillSync",
        "scryptSync",
        "existsSync", // from path
        "readFileSync", // from jsonfile
        "writeFileSync" // from jsonfile
    ]
}
class SyncCallExpr extends CallExpr {
	SyncCallExpr() {
  		isSynchronousFctName(this.getCalleeName())
  	}
}

int getNumLOC() {
	result = sum( any(File f).getNumberOfLinesOfCode())
}
int getNumFunctionsInFile( File f) {
	result = count( Function fct | fct.getFile() = f)
}
int getNumFilesInFolder(Folder d) {
	result = count(File f | f.getParentContainer() = d and f.getExtension() = "js" )
}
int getNumFiles() {
	result = sum(getNumFilesInFolder( any(Folder f) ))
}
int getNumFunctions() {
	result = sum( getNumFunctionsInFile( any(File f)))
}
int getNumSyncFunctionsInFile( SyncCallExpr c) {
	result = count(  c )
}
int getNumSyncFunctions() {
	result = sum( getNumSyncFunctionsInFile( any(SyncCallExpr c)))
}

from Expr e
where e.getFile() instanceof SourceFile 
select getNumLOC() as LOC, getNumFiles() as Files, getNumFunctions() as Functions
