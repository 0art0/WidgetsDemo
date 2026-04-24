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

#html Plot fun (x : Float) ↦ x^3 + 2*x + 5

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
    <div style={cardStyle}>
      <div>
        <h2 style={json% {margin: "0 0 4px 0", color: "#0f172a"}}>Interactive Graph Builder</h2>
        <p style={hintStyle}>Add vertices and connect them with edges.</p>
        <p style={hintStyle}>Vertices: {.text s!"{(← vertices.get).size}"} | Edges: {.text s!"{(← edges.get).size}"}</p>
      </div>
      <div style={graphPanelStyle}>
        <GraphDisplay vertices={← vertices.get} edges={← edges.get} />
      </div>
      <div style={controlsStyle}>
        <div style={rowStyle}>
          <span style={labelStyle}>Add a vertex</span>
      <TextInput
        placeholder="Enter a name for a new vertex"
        value={← vertexId.get}
        onChange={← asEventRef vertexId.set} />
          <Button onClick={← asEventRef fun () ↦ do
            vertices.modify (.push (v := { id := (← vertexId.get) }))
            vertexId.set ""
          }>Add vertex</Button>
        </div>
        <div style={rowStyle}>
          <span style={labelStyle}>Connect two vertices</span>
          <span style={hintStyle}>Source vertex</span>
          <Dropdown
            options={(← vertices.get).map Vertex.id}
            selectedIndex={← edgeSourceIdx?.get}
            onChange={← asEventRef <| edgeSourceIdx?.set ∘ .some} />
          <span style={hintStyle}>Target vertex</span>
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
    </div>
  </div>
where
  cardStyle : Json := json% {
    border: "1px solid #d7dde8",
    borderRadius: "16px",
    padding: "18px",
    background: "linear-gradient(180deg, #fafcff 0%, #f3f7fb 100%)",
    boxShadow: "0 10px 24px rgba(15, 23, 42, 0.08)",
    display: "grid",
    gap: "16px"
  }
  graphPanelStyle : Json := json% {
    padding: "14px",
    borderRadius: "12px",
    background: "#ffffff",
    border: "1px solid #e5eaf1"
  }
  controlsStyle : Json := json% {
    display: "grid",
    gap: "12px"
  }
  rowStyle : Json := json% {
    display: "grid",
    gap: "8px",
    padding: "12px",
    borderRadius: "12px",
    background: "rgba(255, 255, 255, 0.9)",
    border: "1px solid #e5eaf1"
  }
  labelStyle : Json := json% {
    fontSize: "0.9rem",
    fontWeight: "600",
    color: "#334155"
  }
  hintStyle : Json := json% {
    fontSize: "0.9rem",
    color: "#64748b",
    margin: "0"
  }


#html interactiveGraphBuilder

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

#slides Working /-!

# Implementing stateful widgets in Lean

Roughly, stateful widgets work in the following way:

- The state is represented by a mutable `Ref` on the Lean side. In particular, this means the state can be arbitrary Lean data

---

- Effects are represented by functions wrapped in `WithRpcRef`, which allows JavaScript code to provide them back to Lean to run at the appropriate time

---

- Each of the custom components `Button`, `TextInput`, `Slider`, etc., is configured to send out a signal that the `StatefulHtml` component picks up and triggers its re-render.

-/

#html show BaseIO Html from do
  let count ← IO.mkRef 0
  return (
    <StatefulHtml html={← WithRpcRef.mk <| return (
    <div>
      <Button onClick={← WithRpcRef.mk
        (fun _ ↦ RequestM.asTask do count.modify (· + 1))}>
        <text>Click me!</text>
      </Button>
      <p>Count: {.text s!"{← count.get}"}</p>
    </div>
    )} />
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






#html show IO Html from do
  return <Button onClick={← WithRpcRef.mk <| fun _ ↦ applyEdit {
    newText := "#check 1 + 1",
    range := { start := { line := 325, character := 0 },
                «end» := { line := 325, character := 0 } } }}>
      Click to insert a command into the editor
    </Button>

#slides InteractiveM /-!

## Multiple-turn interactions

In addition to the kinds of widgets demonstrated above, it would be nice to have a
monadic style of programming user-interactions to iteratively and interactively construct pieces
of data in Lean.

## Acknowledgements

In the context of this work, acknowledgements are due to

- Jovan Gerbscheid, for suggesting the idea of the `InteractiveM` monad
- Mirek Olšák, for implementing a prototype of the `InteractiveM` monad using different underlying principles
- Siddharth Bhat, for pointing me to the "Continuation monad" and helping with prototyping the initial version of the monad

## The `InteractiveM` monad

The `InteractiveM` monad uses the continuation monad behind the scenes to construct a
nested HTML structure that keeps track of the sequence of user interactions that is to be performed.

-/

#check InteractiveT

#html InteractiveT.run (m := BaseIO) do
  createButton "Click me!"
  createButton "Click me again"
  if (← askBool "Would you like to continue?") then
    let name ← askString "Choose the next button label"
    createButton name
    let language ← askChoices "What is your favorite programming language?" #["Lean"]
    createHtml <| <p>Great choice! {.text language} is indeed a great language.</p>
  else
    createHtml <| <p>Goodbye!</p>

#slides Conclusion /-!

## Future work

- The demos shown so far should in principle be compatible with arbitrary monads that extend `IO`, but currently are designed only for `IO`.
- Once the code is stable enough, the plan is to PR it to `ProofWidgets`.

## Conclusion

- Being able to conveniently define not just pure graphical components, but also ones that implement state and effects entirely from within Lean, will hopefully open up more opportunities for using widgets in Mathlib.

- The eventual goal is to use this framework to assist in building a suite of interactive graphical components that show up in the infoview in response to user selections in the tactic state that tactic writers can add their own widgets to.

-/
