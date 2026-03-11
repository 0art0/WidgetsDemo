module

public meta import WidgetsDemo.StatefulHtmlComponents
public meta import WidgetsDemo.InteractiveMonad
public meta import ProofWidgets.Demos.Graph.Basic
public meta import LeanSlides

public meta section

open Lean ProofWidgets Jsx Server

#check DropdownProps

#slides Introduction /-!

# Title slide

-/

open GraphDisplay in
#html <GraphDisplay
    vertices={#["a", "b", "c", "d", "e", "f"].map ({id := ·})}
    edges={#[("b","c"), ("d","e"), ("e","f"), ("f","d")].map mkEdge}
  />

open GraphDisplay in
def interactiveGraphBuilder : IO Html := do
  let vertices : IO.Ref (Array Vertex) ← IO.mkRef #[]
  let edges : IO.Ref (Array Edge) ← IO.mkRef #[]
  let vertexId : IO.Ref String ← IO.mkRef ""
  let edgeSourceIdx : IO.Ref (Option Nat) ← IO.mkRef none

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
      -- <Dropdown
      --   options={(← vertices.get).map .id}

    </div>
  </div>

#html interactiveGraphBuilder

section InteractiveCheck

structure Trie (α : Type _) where
  values : Array α
  tries : AssocList Char (Trie α)

variable {α : Type _}

def Trie.empty : Trie α := .mk #[] ∅

instance : EmptyCollection (Trie α) where
  emptyCollection := .empty

def Trie.insertCharList (trie : Trie α) (chars : List Char) (a : α) : Trie α :=
  let { values, tries } := trie
  match chars with
  | [] => { values := (values.push a), tries }
  | c :: chars =>
    match tries.find? c with
    | some child => { values, tries := (tries.insert c (child.insertCharList chars a)) }
    | none => { values, tries := (tries.insert c ((∅ : Trie α).insertCharList chars a)) }

def Trie.insertString (trie : Trie α) (s : String) (a : α) : Trie α :=
  trie.insertCharList s.toList a

def Trie.insertName (trie : Trie α) (n : Name) (a : α) : Trie α :=
  if n.isInternalDetail || n.isImplementationDetail || n.isMetaprogramming then
    trie
  else
    trie.insertString n.toString a

def Trie.lookupTrieAtCharList (trie : Trie α) (chars : List Char) : Trie α :=
  match chars with
  | [] => trie
  | c :: chars =>
    match trie.tries.find? c with
    | some child => child.lookupTrieAtCharList chars
    | none => ∅

def Trie.lookupTrieAtString (trie : Trie α) (s : String) : Trie α :=
  trie.lookupTrieAtCharList s.toList

def Trie.lookupTrieAtName (trie : Trie α) (n : Name) : Trie α :=
  trie.lookupTrieAtString n.toString

partial def Trie.allValues (trie : Trie α) : Array α :=
  trie.tries.foldl (init := trie.values) (fun vals _ t ↦ vals ++ t.allValues)

def Trie.concatTries (tries : Array (Trie α)) (initValues : Array α := ∅) (initTries : Array (Trie α) := ∅) : Array α × Array (Trie α) :=
  tries.foldl (init := (initValues, initTries)) fun (valuesAcc, triesAcc) trie ↦
    ( valuesAcc ++ trie.values, triesAcc ++ trie.tries.toList.toArray.map Prod.snd)

partial def Trie.allValuesBreadthFirst (trie : Trie α) (lengthBuffer? : Option Nat := none) : Array α := Id.run do
  let mut (values, tries) : Array α × Array (Trie α) := (∅, #[trie])
  let mut counter : Nat := 0
  while !tries.isEmpty && (if let some lengthBuffer := lengthBuffer? then counter ≤ lengthBuffer else true) do
    (values, tries) := Trie.concatTries tries (initValues := values)
    counter := counter + 1
  return values

partial def Trie.lookupStringSuffixes (trie : Trie α) (s : String) : Array α :=
  (trie.lookupTrieAtString s).allValues

partial def Trie.lookupNameSuffixes (trie : Trie α) (n : Name) : Array α :=
  trie.lookupStringSuffixes n.toString

partial def Trie.lookupStringSuffixesBreadthFirst (trie : Trie α) (s : String) (lengthBuffer? : Option Nat := none) : Array α :=
  (trie.lookupTrieAtString s).allValuesBreadthFirst lengthBuffer?

partial def Trie.lookupNameSuffixesBreadthFirst (trie : Trie α) (n : Name) (lengthBuffer? : Option Nat := none) : Array α :=
  (trie.lookupTrieAtName n).allValuesBreadthFirst lengthBuffer?

def buildConstantsTrie {M} [Monad M] [MonadEnv M] : M (Trie ConstantInfo) := do
  let env ← getEnv
  return env.constants.fold (init := ∅) <| fun trie name constInfo ↦
    if Meta.LazyDiscrTree.blacklistInsertion env name || name.isMetaprogramming then
      trie
    else
      trie.insertName name constInfo

end InteractiveCheck
