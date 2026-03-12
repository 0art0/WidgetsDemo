module

public meta import WidgetsDemo.StatefulHtmlComponents
public meta import WidgetsDemo.InteractiveMonad
public import WidgetsDemo.Trie
public import ProofWidgets.Demos.Graph.Basic
public import ProofWidgets.Demos.Rubiks
public import ProofWidgets.Demos.InteractiveSvg
public import ProofWidgets.Demos.Euclidean
public import ProofWidgets.Demos.Plot
public import ProofWidgets.Demos.Graph.ExprGraph
public import LeanSlides

public meta section

#set_pandoc_options "-V" "revealjs-url=https://unpkg.com/reveal.js@5.2.1"


open Lean ProofWidgets Jsx Server

#slides Widgets /-!

## Stateful ProofWidgets in Lean

#### Enabling multi-turn user interactions in the infoview

**Anand Rao Tadipatri**

_University of Cambridge_

## What are widgets?

- The Lean infoview in VS Code is actually a full-fledged web browser capable of rendering arbitrary HTML and JavaScript code.

- The `ProofWidgets` library, developed primarily by Wojciech Nawrocki and Ed Ayers, defines abstractions, datastructures and notation that make it convenient for users to display custom web code in the infoview.

## Further details on widgets

Some features that the `ProofWidgets` library supports are

- Writing JSX-like markup to define **pure components** directly in Lean
- Defining *components* in Lean that take in structured Lean objects and pass them to a piece of JavaScript code exporting a React component
- Calling Lean functions from JavaScript via remote procedure call (RPC)

-/

-- An example from `ProofWidgets/Demos/Jsx`
def htmlLetters : Array ProofWidgets.Html := #[
    <span style={json% {color: "red"}}>H</span>,
    <span style={json% {color: "yellow"}}>T</span>,
    <span style={json% {color: "green"}}>M</span>,
    <span style={json% {color: "blue"}}>L</span>
  ]

#html <b>You can use {...htmlLetters} in Lean {.text s!"{1 + 3}"}! <hr/> </b>

#html <iframe src={"https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.ITP.2023.24"} width="100%" height="600px" />

-- An example from `ProofWidgets/Demos/Graph/Basic`
open GraphDisplay in
#html <GraphDisplay
    vertices={#["a", "b", "c", "d", "e", "f", "g"].map ({id := ·})}
    edges={#[("b","c"), ("d","e"), ("e","f"), ("f","d")].map mkEdge}
  />

section RpcDemo

structure NoProps
deriving ToJson, FromJson

structure Result where
  msg : String
deriving ToJson, FromJson

@[server_rpc_method]
def sampleRpcMethod : NoProps → RequestM (RequestTask Result) := fun {} => RequestM.asTask do
  IO.sleep 1000
  return { msg := "Hello from Lean!" }

@[widget_module]
def RpcDemo : Component NoProps where
  javascript := "
    import * as React from 'react'
    import { useRpcSession } from '@leanprover/infoview'

    export default function(props) {
      const [result, setResult] = React.useState(null)
      const rs = useRpcSession()
      const onClick = async () => {
        const res = await rs.call('sampleRpcMethod', null)
        setResult(res)
      }
      return React.createElement('div', null,
        React.createElement('button', { onClick }, 'Call RPC method'),
        result ? React.createElement('p', null, result.msg) : React.createElement('p', null, 'No result yet')
      )
    }
  "

#html <RpcDemo />

end RpcDemo

section Demos

/-!

# Some demos from the `ProofWidgets` repository

-/

def props : RubiksProps := {seq := #["L","L","D⁻¹","U⁻¹","L","D","D","L","U⁻¹","R","D","F","F","D"]}

#widget Rubiks with props

open IncidenceGeometry in
example [IncidenceGeometry] {a b : Point} (_hab : a ≠ b) :
    ∃ L M c, onLine a L ∧ onLine b M ∧ onLine c M ∧ onLine c L := by
  with_panel_widgets [EuclideanConstructions]
  sorry

#html Plot fun (x : Float) ↦ x^2

def x : Nat := 0
def y : Nat := 1
def bar (c : Nat) : Nat × Int := (x + y * c, x / y)

-- Put your cursor here.
#expr_graph bar

end Demos

#slides StatefulWidgets /-!

## The need for stateful widgets

While the current set of features of the `ProofWidgets` library
offers a fantastic suite of tools for generating and displaying graphics
in the infoview, using them to generate graphics on the fly can be a bit cumbersome.

## The need for stateful widgets

In particular, defining a new widget in Lean usually requires first
writing a TypeScript file, compiling it to JavaScript and then reading in
the JavaScript file as a Lean string, which can get in the way of being able to define new graphical widgets on the fly.

## The need for stateful widgets

One can imagine a future where tactic writers can also implement custom interactive widgets that show up in the infoview in response to
relevant selections by the user in the tactic state, and that infoview interactions becomes the primary mode of communicating with Lean for beginning users.

## The need for stateful widgets

A recent talk in Lean Together 2026 by Jovan Gerbscheid features some of the work he has been doing in this direction.

In this context, being able to conveniently define rich widgets with states and effects becomes essential, and
it is towards this goal that the stateful widget framework that is the subject of this talk were developed.

-/

open GraphDisplay in
def interactiveGraphBuilder : IO Html := do
  let vertices : IO.Ref (Array Vertex) ← IO.mkRef #[]
  let edges : IO.Ref (Array Edge) ← IO.mkRef #[]
  let vertexId : IO.Ref String ← IO.mkRef ""
  let edgeSourceIdx? : IO.Ref (Option Nat) ← IO.mkRef none
  let edgeTargetIdx? : IO.Ref (Option Nat) ← IO.mkRef none
  createStatefulHtml <| return <div>
    <h2>Interactive Graph Builder</h2>
    <GraphDisplay vertices={← vertices.get} edges={← edges.get} />
    <hr />
    <div>
      <TextInput
        placeholder="Enter a name for a new vertex"
        value={← vertexId.get}
        onChange={← asEventRef vertexId.set} />
      <Button onClick={← asEventRef fun () ↦ do
        vertices.modify (.push (v := { id := (← vertexId.get) }))
        vertexId.set ""
      }>Add vertex</Button>
    </div>
    <div>
      <span>Source vertex</span>
      <Dropdown
        options={(← vertices.get).map Vertex.id}
        selectedIndex={← edgeSourceIdx?.get}
        onChange={← asEventRef <| edgeSourceIdx?.set ∘ .some} />
      <span>Target vertex</span>
      <Dropdown
        options={(← vertices.get).map Vertex.id}
        selectedIndex={← edgeTargetIdx?.get}
        onChange={← asEventRef <| edgeTargetIdx?.set ∘ .some} />
      <Button onClick={← asEventRef fun () ↦ do
        let vertices ← vertices.get
        let source? := if let some sourceIdx := (← edgeSourceIdx?.get) then vertices[sourceIdx]? else none
        let target? := if let some targetIdx := (← edgeTargetIdx?.get) then vertices[targetIdx]? else none
        let edge? : Option Edge := return { source := (← source?).id, target := (← target?).id }
        if let some edge := edge? then
          edges.modify (.push (v := edge))
      }>Add edge</Button>
    </div>
  </div>

#html interactiveGraphBuilder

#slides Working /-!


-/

#html show MetaM Html from do
  let library ← buildConstantsTrie
  let constName : IO.Ref String ← IO.mkRef ""
  let bufferLength : IO.Ref Nat ← IO.mkRef 0
  createStatefulHtml <| return (
    <div>
      <TextInput
        value={← constName.get}
        placeholder={"Enter a Lean identifier"}
        onChange={← asEventRef constName.set} />
      <hr />
      <span>Buffer length for library results: </span>
      <Slider
        min={some 0}
        max={some 10}
        value={← bufferLength.get}
        onChange={← asEventRef bufferLength.set} />
      {.element "div" #[] <| (library.lookupStringSuffixesBreadthFirst (← constName.get) (some (← bufferLength.get))).map (fun info ↦
        <div style={json% {border: "1px solid black", margin: "5px", padding: "5px"}}>
          <p>{.text info.name.toString}</p>
        </div>
      )}
    </div>
  )

#html show BaseIO Html from do
  let count ← IO.mkRef 0
  createStatefulHtml <| return (
    <div>
      <Button onClick={← WithRpcRef.mk
        (fun _ ↦ RequestM.asTask do count.modify (· + 1))}>
        <text>Click me!</text>
      </Button>
      <p>Count: {.text s!"{← count.get}"}</p>
    </div>
)

def applyEdit (edit : Lsp.TextEdit) : RequestM (RequestTask Unit) := do
  return (← ServerTask.mapCheap (handleServerResponse (α := Unit)) <$>
    Server.RequestM.sendServerRequest Lsp.ApplyWorkspaceEditParams Unit "workspace/applyEdit"
    { edit := .ofTextEdit
        (Server.FileWorker.EditableDocument.versionedIdentifier (← read).doc)
        edit })
where
  handleServerResponse {α} : ServerRequestResponse α → Except RequestError α := fun
    | .success res => .ok res
    | .failure code message => .error { code, message }

#check 1 + 1

#html show IO Html from do
  return <Button onClick={← WithRpcRef.mk <| fun _ ↦ applyEdit {
    newText := "#check 1 + 1",
    range := { start := { line := 250, character := 0 },
                «end» := { line := 250, character := 0 } } }}>
      Click to insert a command into the editor
    </Button>

#slides InteractiveM /-!

## Multiple-turn interactions

## The `InteractiveM` monad

## Acknowledgements

In the context of this work, acknowledgements are due to

- Jovan Gerbscheid, for suggesting the idea of the `InteractiveM` monad
- Mirek Olšák, for implementing a prototype of the `InteractiveM` monad using different underlying principles
- Siddharth Bhat, for pointing me to the "Continuation monad" and helping with prototyping the initial version of the monad

-/

#slides Conclusion /-!

## Future work

-/
