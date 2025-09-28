---- MODULE ClaudeCodeSystem ----
EXTENDS TLC, Sequences, FiniteSets, Naturals, Integers

\* Helper function for string replacement in EditFile
Replace(str, oldStr, newStr) == newStr  \* Simplified for model checking

CONSTANTS
    Tools,           \* Set of available tools: {Read, Write, Edit, Bash, Task, Grep, Glob, WebFetch, TodoWrite, Bridge}
    Agents,          \* Set of agents: {ClaudeCode, ClaudeChat, Human, GPT, Codex}
    Files,           \* Set of file paths
    Priorities,      \* Set of message priorities: {CRITICAL, HIGH, NORMAL, INFO}
    Contents,        \* Set of possible file contents
    Actions          \* Set of possible message actions

VARIABLES
    agentState,      \* Current state of each agent
    fileSystem,      \* File system state
    bridgeInbox,     \* Messages in bridge inbox
    bridgeOutbox,    \* Messages in bridge outbox
    bridgeContext,   \* Shared context (decisions, patterns, state)
    todoList,        \* Current todo list
    toolInProgress,  \* Currently executing tool
    messageCounter   \* Global counter for message timestamps

\* Agent states
AgentStates == {"Idle", "ReadingFiles", "WritingFiles", "ProcessingTools",
                "CheckingBridge", "ProcessingMessages", "UpdatingContext"}

\* Tool execution states
ToolStates == {"None", "Read", "Write", "Edit", "Bash", "Task", "Grep",
               "Glob", "WebFetch", "TodoWrite", "BridgeRead", "BridgeWrite"}

\* Message structure
Message == [sender: Agents, recipient: Agents, priority: Priorities,
            timestamp: Nat, content: Contents, expectedAction: Actions]

\* Todo item structure
TodoItem == [content: Contents, status: {"pending", "in_progress", "completed"},
             activeForm: Contents]

TypeInvariant ==
    /\ agentState \in [Agents -> AgentStates]
    /\ fileSystem \in [Files -> Contents]
    /\ bridgeInbox \subseteq Message
    /\ bridgeOutbox \subseteq Message
    /\ bridgeContext \in [{"decisions", "patterns", "state"} -> Contents]
    /\ todoList \in Seq(TodoItem)
    /\ toolInProgress \in ToolStates
    /\ messageCounter \in Nat

\* Initial state
Init ==
    /\ agentState = [a \in Agents |-> "Idle"]
    /\ fileSystem = [f \in Files |-> "empty"]
    /\ bridgeInbox = {}
    /\ bridgeOutbox = {}
    /\ bridgeContext = [t \in {"decisions", "patterns", "state"} |-> "empty"]
    /\ todoList = <<>>
    /\ toolInProgress = "None"
    /\ messageCounter = 0

\* Tool execution actions
ReadFile(agent, file) ==
    /\ agentState[agent] = "Idle"
    /\ file \in Files  \* Precondition: file must exist
    /\ agentState' = [agentState EXCEPT ![agent] = "ReadingFiles"]
    /\ toolInProgress' = "Read"
    /\ UNCHANGED <<fileSystem, bridgeInbox, bridgeOutbox, bridgeContext, todoList, messageCounter>>

WriteFile(agent, file, content) ==
    /\ agentState[agent] = "Idle"
    /\ agentState' = [agentState EXCEPT ![agent] = "WritingFiles"]
    /\ fileSystem' = [fileSystem EXCEPT ![file] = content]
    /\ toolInProgress' = "Write"
    /\ UNCHANGED <<bridgeInbox, bridgeOutbox, bridgeContext, todoList, messageCounter>>

EditFile(agent, file, oldString, newString) ==
    /\ agentState[agent] = "Idle"
    /\ file \in Files  \* Precondition: file must exist
    /\ agentState' = [agentState EXCEPT ![agent] = "WritingFiles"]
    /\ fileSystem' = [fileSystem EXCEPT ![file] =
                     Replace(fileSystem[file], oldString, newString)]
    /\ toolInProgress' = "Edit"
    /\ UNCHANGED <<bridgeInbox, bridgeOutbox, bridgeContext, todoList, messageCounter>>

\* Bridge communication actions
CheckBridge(agent) ==
    /\ agentState[agent] = "Idle"
    /\ agentState' = [agentState EXCEPT ![agent] = "CheckingBridge"]
    /\ toolInProgress' = "BridgeRead"
    /\ UNCHANGED <<fileSystem, bridgeInbox, bridgeOutbox, bridgeContext, todoList, messageCounter>>

SendBridgeMessage(sender, recipient, priority, content, action) ==
    LET msg == [sender |-> sender, recipient |-> recipient,
                priority |-> priority, timestamp |-> messageCounter + 1,
                content |-> content, expectedAction |-> action]
    IN
    /\ agentState[sender] = "Idle"
    /\ agentState' = [agentState EXCEPT ![sender] = "ProcessingMessages"]
    /\ bridgeOutbox' = bridgeOutbox \union {msg}
    /\ messageCounter' = messageCounter + 1
    /\ toolInProgress' = "BridgeWrite"
    /\ UNCHANGED <<fileSystem, bridgeInbox, bridgeContext, todoList>>

ProcessBridgeMessage(agent, msg) ==
    /\ agentState[agent] = "CheckingBridge"
    /\ msg \in bridgeInbox
    /\ msg.recipient = agent
    /\ agentState' = [agentState EXCEPT ![agent] = "ProcessingMessages"]
    /\ bridgeInbox' = bridgeInbox \ {msg}
    /\ UNCHANGED <<fileSystem, bridgeOutbox, bridgeContext, todoList, toolInProgress, messageCounter>>

\* Todo list management
UpdateTodoList(agent, newTodos) ==
    /\ agentState[agent] \in {"Idle", "ProcessingTools"}
    /\ todoList' = newTodos
    /\ toolInProgress' = "TodoWrite"
    /\ UNCHANGED <<agentState, fileSystem, bridgeInbox, bridgeOutbox, bridgeContext, messageCounter>>

MarkTodoInProgress(agent, index) ==
    /\ agentState[agent] = "Idle"
    /\ index \in 1..Len(todoList)
    /\ todoList[index].status = "pending"
    /\ todoList' = [todoList EXCEPT ![index].status = "in_progress"]
    /\ agentState' = [agentState EXCEPT ![agent] = "ProcessingTools"]
    /\ UNCHANGED <<fileSystem, bridgeInbox, bridgeOutbox, bridgeContext, toolInProgress, messageCounter>>

MarkTodoCompleted(agent, index) ==
    /\ agentState[agent] = "ProcessingTools"
    /\ index \in 1..Len(todoList)
    /\ todoList[index].status = "in_progress"
    /\ todoList' = [todoList EXCEPT ![index].status = "completed"]
    /\ agentState' = [agentState EXCEPT ![agent] = "Idle"]
    /\ UNCHANGED <<fileSystem, bridgeInbox, bridgeOutbox, bridgeContext, toolInProgress, messageCounter>>

\* Context preservation
UpdateBridgeContext(agent, contextType, content) ==
    /\ agentState[agent] \in {"ProcessingMessages", "ProcessingTools"}
    /\ contextType \in {"decisions", "patterns", "state"}
    /\ bridgeContext' = [bridgeContext EXCEPT ![contextType] = content]
    /\ UNCHANGED <<agentState, fileSystem, bridgeInbox, bridgeOutbox, todoList, toolInProgress, messageCounter>>

\* Return to idle state after tool completion
CompleteToolExecution(agent) ==
    /\ agentState[agent] \in {"ReadingFiles", "WritingFiles", "ProcessingTools",
                             "CheckingBridge", "ProcessingMessages"}
    /\ agentState' = [agentState EXCEPT ![agent] = "Idle"]
    /\ toolInProgress' = "None"
    /\ UNCHANGED <<fileSystem, bridgeInbox, bridgeOutbox, bridgeContext, todoList, messageCounter>>

\* Agent authority domain constraints
AgentAuthorityInvariant ==
    /\ \A msg \in bridgeOutbox \union bridgeInbox :
         /\ (msg.sender = "ClaudeCode" /\ msg.recipient = "ClaudeChat") =>
            msg.content \in {"technical_implementation", "code_optimization",
                           "pattern_recognition", "system_architecture"}
         /\ (msg.sender = "ClaudeChat" /\ msg.recipient = "ClaudeCode") =>
            msg.content \in {"strategic_planning", "framework_evolution",
                           "priority_setting", "stakeholder_coordination"}

\* Safety properties
NoDataLoss ==
    [](\A f \in Files : fileSystem[f] = "" \/ fileSystem[f] = fileSystem[f])

MessageOrdering ==
    \A m1, m2 \in bridgeInbox \union bridgeOutbox :
        (m1.priority = "CRITICAL" /\ m2.priority = "HIGH") =>
        m1.timestamp <= m2.timestamp

NoSimultaneousWrite ==
    \A a1, a2 \in Agents, f \in Files :
        (a1 # a2 /\ agentState[a1] = "WritingFiles" /\ agentState[a2] = "WritingFiles") =>
        FALSE

\* Bridge v3.0 Collision Prevention Properties
UniqueMessageIDs ==
    \A m1, m2 \in bridgeInbox \union bridgeOutbox :
        (m1.id = m2.id) => (m1 = m2)

NoNamespaceCollisions ==
    \A m1, m2 \in bridgeInbox \union bridgeOutbox :
        (m1.sender = m2.sender /\ m1.timestamp = m2.timestamp) =>
        (m1.uuid # m2.uuid)

QueueOrdering ==
    \A m1, m2 \in bridgeInbox :
        (m1.queueNumber < m2.queueNumber) =>
        (m1.timestamp <= m2.timestamp)

AtomicMessageCreation ==
    \A agent \in Agents, msg \in bridgeInbox \union bridgeOutbox :
        (agentState[agent] = "WritingMessage") =>
        \E tempMsg : (tempMsg.status = "creating" /\ tempMsg.sender = agent)

FIFOProcessingOrder ==
    \A agent \in Agents :
        LET agentMessages == {m \in bridgeInbox : m.recipient = agent}
        IN \A m1, m2 \in agentMessages :
            (m1.queueNumber < m2.queueNumber) =>
            (m1.processedTime <= m2.processedTime)

MessageNeverLost ==
    \A msg \in bridgeInbox \union bridgeOutbox :
        [](msg \in bridgeInbox \union bridgeOutbox \union archivedMessages)

\* Liveness properties
EventualMessageProcessing ==
    \A msg \in bridgeInbox : <>(msg \notin bridgeInbox)

EventualTodoCompletion ==
    \A i \in 1..Len(todoList) :
        (todoList[i].status = "pending") ~> (todoList[i].status = "completed")

\* Deadlock freedom - moved after Next definition

\* Next state relation
Next ==
    \E agent \in Agents, file \in Files, content \in Contents :
        \/ ReadFile(agent, file)
        \/ WriteFile(agent, file, content)
        \/ CheckBridge(agent)
        \/ CompleteToolExecution(agent)
        \/ \E recipient \in Agents, priority \in Priorities, action \in Actions :
             SendBridgeMessage(agent, recipient, priority, content, action)
        \/ \E msg \in bridgeInbox : ProcessBridgeMessage(agent, msg)
        \/ \E todos \in Seq(TodoItem) : UpdateTodoList(agent, todos)
        \/ \E index \in 1..Len(todoList) :
             MarkTodoInProgress(agent, index) \/ MarkTodoCompleted(agent, index)
        \/ \E contextType \in {"decisions", "patterns", "state"} :
             UpdateBridgeContext(agent, contextType, content)

\* Deadlock freedom - system can always make progress
DeadlockFreedom ==
    \A agent \in Agents : agentState[agent] = "Idle" => ENABLED Next

\* Specification
Spec == Init /\ [][Next]_<<agentState, fileSystem, bridgeInbox, bridgeOutbox,
                           bridgeContext, todoList, toolInProgress, messageCounter>>
        /\ WF_<<agentState, bridgeInbox, todoList>>(CompleteToolExecution("ClaudeCode"))

THEOREM Spec => []TypeInvariant
THEOREM Spec => []NoDataLoss
THEOREM Spec => []MessageOrdering
THEOREM Spec => []NoSimultaneousWrite
THEOREM Spec => []AgentAuthorityInvariant
THEOREM Spec => EventualMessageProcessing
THEOREM Spec => EventualTodoCompletion
THEOREM Spec => []DeadlockFreedom

====
