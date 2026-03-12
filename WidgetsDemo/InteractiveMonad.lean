module

public import WidgetsDemo.StatefulHtmlComponents

public meta section

open Lean ProofWidgets Server Jsx Elab Command

abbrev ContT (m : Type → Type) (r a : Type) := (a → m r) → m r

def ContT.pure {m r α} (a : α) : ContT m r α := fun k ↦ k a

def ContT.bind {m r α β} (x : ContT m r α) (f : α → ContT m r β) : ContT m r β :=
  fun k ↦ x (fun a ↦ f a k)

instance {m r} [Monad m] : Monad (ContT m r) where
  pure := ContT.pure
  bind := ContT.bind

instance {m r} [Monad m] : MonadLift m (ContT m r) where
  monadLift {α} (ma : m α) : ContT m r α := fun k ↦ do
    let a ← ma
    k a

def ContT.eval {m r α} (x : ContT m r α) (k : α → m r) : m r := x k

def ContT.run {m r} [Monad m] (x : ContT m r r) : m r := x.eval Pure.pure

def ContT.extract {m α} [Monad m] [MonadLiftT (ST IO.RealWorld) m] (x : ContT m Unit α) : m (Option α) := do
  let resultRef : ST IO.RealWorld (IO.Ref (Option α)) := IO.mkRef none
  let result : IO.Ref (Option α) ← resultRef
  x.eval (fun a ↦ result.set (some a))
  result.get

abbrev InteractiveT (m : Type → Type) := ReaderT (IO.Ref Html) (ContT m Unit)

def InteractiveT.run {m} [Monad m] [MonadLiftT BaseIO m] (code : InteractiveT m Unit) : m Html := do
  let htmlRef ← IO.mkRef <text>Loading...</text>
  ReaderT.run code htmlRef |>.run
  createStatefulHtml htmlRef.get

def createButton (label : String) : InteractiveT BaseIO Unit := fun htmlRef k ↦ do
  htmlRef.set <| <Button onClick={← asEventRef fun () ↦ k ()}>{.text label}</Button>

def createHtml (html : Html) : InteractiveT BaseIO Unit := fun htmlRef k ↦ do
  htmlRef.set html
  k ()

def askBool (question : String) : InteractiveT BaseIO Bool := fun htmlRef k ↦ do
  htmlRef.set <|
    <div>
      <p>{.text question}</p>
      <Button onClick={← asEventRef fun () ↦ k true}>Yes</Button>
      <Button onClick={← asEventRef fun () ↦ k false}>No</Button>
    </div>

def askString (question : String) : InteractiveT BaseIO String := fun htmlRef k ↦ do
  htmlRef.set <|
    <TextSubmitBox
      placeholder={question}
      value={""}
      onSubmit={← asEventRef fun s ↦ k s} />
