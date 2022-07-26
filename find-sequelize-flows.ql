import javascript

class SequelizeAPI extends string {
    SequelizeAPI() {
        this in ["findAll", "findOne", "findAndCountAll", "findByPk", "count"]
    }
}

class SequelizeSources extends string {
    SequelizeSources() {
        this in ["findAll", "findAndCountAll"]
    }
}

class SequelizeSinks extends string {
    SequelizeSinks() {
        this in ["findAll", "findOne", "findAndCountAll", "findByPk", "count"]
    }
}

class SequelizeTaintConfiguration extends TaintTracking::Configuration {
    SequelizeTaintConfiguration() { this = "SequelizeTaintConfiguration" }

    override predicate isSource(DataFlow::Node source) {
        ((DataFlow::InvokeNode) source).getCalleeName() instanceof SequelizeSources
    }

    override predicate isSink(DataFlow::Node sink) {
        sink instanceof SequelizeAPIArgument and
        exists(DataFlow::InvokeNode sq | sq.getCalleeName() instanceof SequelizeSinks and sq.getAnArgument().getAstNode() = sink.getAstNode().getParent*())
    }
}

class SequelizeAPIArgument extends DataFlow::Node {
    DataFlow::InvokeNode apiCall;

    SequelizeAPIArgument() {
        this.getAstNode().getParent*() = apiCall.asExpr() and
        apiCall.getCalleeName() instanceof SequelizeAPI
    }

    DataFlow::InvokeNode getAPICall() {
        result = apiCall
    }
}

class CallToLoopingFunction extends CallExpr {
    CallToLoopingFunction() {
        this.getCalleeName() in ["flatMap", "forEach", "map", "filter", "every", "some", "reduce", "all", "any"]
    }
}

predicate isNPlusOne(DataFlow::Node source, DataFlow::Node sink) {
    // Is there a loop between the source and sink?
    exists(LoopStmt ls | sink.getAstNode().getParent*() = ls.getBody() and
                         ls.getTest().getEnclosingFunction() = source.asExpr().getEnclosingFunction() and
                         not source.getAstNode().getParent*() = ls.getBody()) or
    // Or is there a loop function between the source and sink?
    exists(CallToLoopingFunction ce | sink.getAstNode().getParent*() = ce.getArgument(0) and
                                      ce.getEnclosingFunction() = source.asExpr().getEnclosingFunction() and
                                      not source.getAstNode().getParent*() = ce.getArgument(0))
}

predicate noIfBetween(DataFlow::Node source, DataFlow::Node sink) {
    not exists(IfStmt ifStmt | sink.getAstNode().getParent*() = ifStmt and not source.getAstNode().getParent*() = ifStmt)
}

predicate noContinueBetween(DataFlow::Node source, DataFlow::Node sink) {
    not exists(ContinueStmt cStmt | source.getAstNode().getLocation().getStartLine() < cStmt.getLocation().getStartLine() and
                                    cStmt.getLocation().getStartLine() < sink.getAstNode().getLocation().getStartLine())
}

from SequelizeTaintConfiguration cfg, DataFlow::Node source, DataFlow::Node sink
where source != sink and 
    cfg.hasFlow(source, sink) and 
    not exists(DataFlow::Node subSink | sink.asExpr().getParentExpr() = subSink.asExpr() and cfg.hasFlow(source, subSink)) and
    isNPlusOne(source, sink) and
    noIfBetween(source, sink) and
    noContinueBetween(source, sink)
select ((DataFlow::InvokeNode) source).getCalleeName() as Source,
    source.getFile() as Source_File, 
    source.getStartLine() as Source_Start_Ln, 
    source.getEndLine() as Source_End_Ln, 
    ((SequelizeAPIArgument) sink).getAPICall().getCalleeName() as Sink, 
    ((SequelizeAPIArgument) sink).getAPICall().asExpr().getEnclosingStmt().getFile() as Sink_File, 
    ((SequelizeAPIArgument) sink).getAPICall().asExpr().getEnclosingStmt().getLocation().getStartLine() as Sink_Start_Ln, 
    ((SequelizeAPIArgument) sink).getAPICall().asExpr().getEnclosingStmt().getLocation().getEndLine() as Sink_End_Ln,
    sink as ExactSink,
    sink.getAstNode().getLocation().getStartLine() as ExactSinkStartLine,
    sink.getAstNode().getLocation().getEndLine() as ExactSinkEndLine,
    sink.getAstNode().getLocation().getStartColumn() as ExactSinkStartCol,
    sink.getAstNode().getLocation().getEndColumn() as ExactSinkEndCol
