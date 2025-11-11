import LeanSlides
import ProofWidgets
import ProofWidgets.Demos.Rubiks
import ProofWidgets.Demos.InteractiveSvg
import ProofWidgets.Demos.Euclidean
import ProofWidgets.Demos.Plot
import ProofWidgets.Demos.Graph.ExprGraph

open Lean Elab ProofWidgets Server Jsx Json

#set_pandoc_options "-V" "revealjs-url=https://unpkg.com/reveal.js@5.2.0"

elab "#slides" nm:ident doc:Parser.Command.moduleDoc : command =>
  pure ()

#slides Intro /-!

# What are widgets?

- The Lean infoview in VS Code is actually a full-fledged web browser capable of rendering arbitrary HTML and JavaScript code.

- The `ProofWidgets` library, developed primarily by Wojciech Nawrocki and Ed Ayers, defines abstractions, datastructures and notation that make it convenient for users to display custom web code in the infoview.

-/

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

#slides Anatomy /-!

## The anatomy of a widget

---

## The front-end Lean representation

There are two parts to a widget in Lean:

- The `Component`, which specifies how the widget must be rendered
- The `Props`, which are the parameters that can be passed to the `Component`

## Further details

- The `Component` points to a piece of JavaScript code containing a `React` component
- The `Props` must be JSON encodable (technically, `RPC` encodable)
- The widget is typically attached to a piece of syntax in the editor

## A crash course in `React.js`

- `React.js` is a UI library developed by Meta AI that takes a *purely functional* approach to UI design
- A web app is typically modularized into `React` components that take in _props_ as arguments
- Typically, a component depends solely on its props
- React uses an HTML-like syntax called `JSX` (JavaScript eXpression) for components

## The back-end JavaScript representation

- A widget in Lean references a piece of JavaScript code that handles the rendering
- The JavaScript code exports a `React` component
- Typically, the JavaScript code is first written in *TypeScript*, a superset of JavaScript that adds static typing,
  and then compiled to JavaScript
- The `Props` from Lean are passed to the `React` component in the form of a JSON object

-/

#html <iframe src={"https://react.dev/learn"} width="100%" height="600px" />

section FullWidgetExample

structure TermDisplayWidgetProps where
  term : String
  type : String
deriving ToJson, FromJson


@[widget_module]
def TermDisplayWidget : Component TermDisplayWidgetProps where
    javascript := include_str "widget" / "dist" / "termDisplayWidget.js"

def exampleProps : TermDisplayWidgetProps := {term := "Nat", type := "Type"}

#widget TermDisplayWidget with exampleProps

elab stx:"#term_info" term:str ":" type:str : command => Command.runTermElabM fun _ => do
  let props : TermDisplayWidgetProps := {term := term.getString, type := type.getString}
  Widget.savePanelWidgetInfo
    TermDisplayWidget.javascriptHash
    (pure <| toJson props)
    stx

#term_info "Nat" : "Type"

end FullWidgetExample


#slides HtmlWidgets /-!

- Defining widgets using JavaScript code each time can get tedious.

- If a widget is *pure* (i.e., it doesn't have any state or effects), it can be directly in Lean using JSX-like syntax.

-/

section HtmlWidgetExample

local instance : Coe String Html where
    coe := .text

def termDisplay (props : TermDisplayWidgetProps) : Html :=
        <div
          style={json% {
            maxWidth: "500px",
            margin: "40px auto",
            padding: "24px",
            background: "#1e1e2f",
            borderRadius: "12px",
            color: "#f5f5f5",
            fontFamily: "Consolas, monospace",
            boxShadow: "0 8px 20px rgba(0, 0, 0, 0.2)",
            transition: "transform 0.3s"
          }}
        >
          <div style={json% { marginBottom: "16px", borderBottom: "1px solid #444", paddingBottom: "12px" }}>
            <h2 style={json% { fontSize: "1.75rem", margin: 0, color: "#66d9ef" }}>{props.term}</h2>
            <p style={json% { fontSize: "1rem", margin: "8px 0 0", color: "#9cdcfe" }}>
              <em>{props.type}</em>
            </p>
          </div>
          <div style={json% { fontSize: "0.95rem", color: "#ccc" }}>
            <p>
              <strong>Definition:</strong> The term `<span style={json% { color: "#ffd700" }}>{props.term}</span>` is a `<span style={json% { color: "#98c379" }}>{props.type}</span>`.
            </p>
          </div>
        </div>

#html termDisplay { term := "Nat", type := "Type" }

end HtmlWidgetExample

#slides RPC /-!

- Some kinds of data are difficult to pass around as JSON-encoded arguments (for example, functions). In such cases, it's possible to pass a *reference* to the data using `WithRpcRef`.
- It is also possible for code in JavaScript to call Lean functions tagged with `@[server_rpc_method]` via remote procedure call (RPC).
- Such functions must have type `α → RequestM (RequestTask β)` with `[RpcEncodable α]` and `[RpcEncodable β]`.

---

- The `mk_rpc_widget%` elaborator can be used to conveniently define widgets out of server RPC methods that return `Html` objects as output.

-/


deriving instance TypeName for Environment

structure TermDisplayWidgetRemoteProps where
  name : Name
  env : WithRpcRef Environment
deriving RpcEncodable

@[server_rpc_method]
def TermDisplayWidgetRemote.rpc (props : TermDisplayWidgetRemoteProps) : RequestM (RequestTask Html) := RequestM.asTask do
  let .some constInfo := props.env.val.find? props.name | IO.throwServerError "The constant {props.name} is not in the environment."
  let type := constInfo.type
  let typeString ← printExpr type
  return termDisplay { term := props.name.toString, type := typeString }
where
  printExpr (e : Expr) : EIO Exception String := do
    let fmt ← (PrettyPrinter.ppExpr e)
      |>.run' {}
      |>.run' { fileName := default, fileMap := default } { env := props.env.val }
    return toString fmt

@[widget_module]
def TermDisplayWidgetRemote : Component TermDisplayWidgetRemoteProps where
  javascript := include_str "widget" / "dist" / "termDisplayWidgetRemote.js"

#html show CoreM _ from
  return <TermDisplayWidgetRemote name={``Nat.add} env={← WithRpcRef.mk (← getEnv)} />

@[widget_module]
def TermDisplayLeanRPCWidget : Component TermDisplayWidgetRemoteProps :=
  mk_rpc_widget% TermDisplayWidgetRemote.rpc

#html show CoreM _ from
  return <TermDisplayLeanRPCWidget name={``Nat.add} env={← WithRpcRef.mk (← getEnv)} />

elab stx:"#widget_check" t:ident : command => Command.runTermElabM fun _ ↦ do
  let env ← getEnv
  let envRef ← WithRpcRef.mk env
  Widget.savePanelWidgetInfo
    (hash := TermDisplayLeanRPCWidget.javascriptHash)
    (props := do rpcEncode (α := TermDisplayWidgetRemoteProps) { name := t.getId, env := envRef })
    stx

#widget_check Nat.add

section TextReplacementWidget

structure TextReplacementWidgetProps where
  text : String
  replacementRange : Lsp.Range
deriving Server.RpcEncodable

@[server_rpc_method]
def TextReplacementWidget.rpc (props : TextReplacementWidgetProps) : RequestM (RequestTask Html) := RequestM.asTask do
  let editLinkProps : MakeEditLinkProps := .ofReplaceRange' (← RequestM.readDoc).meta props.replacementRange props.text none
  return <div><p>Click to insert the text into the editor</p>{.ofComponent MakeEditLink editLinkProps #[<p>Click here</p>]}</div>

@[widget_module]
def TextReplacementWidget : Component TextReplacementWidgetProps :=
  mk_rpc_widget% TextReplacementWidget.rpc

elab "#self_replace" txt:str : command => Command.runTermElabM fun _ ↦ do
  let stx ← getRef
  let some range := (← getFileMap).lspRangeOfStx? stx | return
  Widget.savePanelWidgetInfo TextReplacementWidget.javascriptHash
    (props := return json%{text: $(txt.getString), replacementRange: $(range)})
    stx

#self_replace "#eval \"Hello!\""

end TextReplacementWidget

#slides PanelWidgets /-!

## Panel widgets

- Panel widgets react to selections made in the proof state displayed in the infoview.

-/

@[server_rpc_method]
def ExamplePanelWidget.rpc (props : PanelWidgetProps) : RequestM (RequestTask Html) := RequestM.asTask do
  let printLocation : SubExpr.GoalLocation → String
  | .hyp fv => s!"Hypothesis {fv.name}\n"
  | .hypType fv pos => s!"Hypothesis {fv.name} type at {pos}\n"
  | .hypValue fv pos => s!"Hypothesis {fv.name} value at {pos}\n"
  | .target pos => s!"Goal type at {pos}\n"
  return .element "details" #[("open", "true")] <|
    #[.element "ul" #[] <| props.selectedLocations.map (Html.text <| printLocation ·.loc)]

@[widget_module]
def ExamplePanelWidget : Component PanelWidgetProps :=
  mk_rpc_widget% ExamplePanelWidget.rpc

-- show_panel_widgets [ExamplePanelWidget]

example (h : 1 + 1 = 2) : 2 + 2 = 4 := by
  with_panel_widgets [ExamplePanelWidget]
  rfl
