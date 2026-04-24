module

public import WidgetsDemo.StatefulHtmlComponents

public meta section

open Lean ProofWidgets Server Jsx Elab Command

/-- Build a CSS-style Json object from string key/value pairs. -/
def mkStyle (pairs : List (String × String)) : Json :=
  .mkObj (pairs.map fun (k, v) => (k, .str v))

/- The board is a 4x4 grid of natural numbers (0 means an empty cell). -/

abbrev Board := Array (Array Nat)

def Board.empty : Board :=
  let zeros : Array Nat := #[0, 0, 0, 0]
  #[zeros, zeros, zeros, zeros]

def Board.get (b : Board) (i j : Nat) : Nat :=
  (b[i]?.getD #[])[j]?.getD 0

def Board.set (b : Board) (i j : Nat) (v : Nat) : Board :=
  b.modify i (·.set! j v)

def Board.emptyCells (b : Board) : Array (Nat × Nat) := Id.run do
  let mut cells : Array (Nat × Nat) := #[]
  for i in [0:4] do
    for j in [0:4] do
      if b.get i j = 0 then
        cells := cells.push (i, j)
  return cells

/-- Drop a random 2 (90%) or 4 (10%) onto an empty cell. -/
def Board.addRandomTile (b : Board) : BaseIO Board := do
  let cells := b.emptyCells
  if cells.isEmpty then return b
  let idx ← IO.rand 0 (cells.size - 1)
  let (i, j) := cells[idx]!
  let r ← IO.rand 0 9
  let newVal := if r = 0 then 4 else 2
  return b.set i j newVal

/-- Slide and merge a single line leftward; returns the merged line and the score gained. -/
partial def mergeLine : List Nat → List Nat × Nat
  | [] => ([], 0)
  | [x] => ([x], 0)
  | x :: y :: rest =>
    if x = y then
      let (rest', s) := mergeLine rest
      (x * 2 :: rest', s + x * 2)
    else
      let (rest', s) := mergeLine (y :: rest)
      (x :: rest', s)

def slideRowLeft (row : Array Nat) : Array Nat × Nat :=
  let filtered := row.toList.filter (· ≠ 0)
  let (merged, score) := mergeLine filtered
  let padded := merged ++ List.replicate (4 - merged.length) 0
  (padded.toArray, score)

def Board.moveLeft (b : Board) : Board × Nat := Id.run do
  let mut newBoard : Board := #[]
  let mut totalScore : Nat := 0
  for i in [0:4] do
    let (row, score) := slideRowLeft (b[i]!)
    newBoard := newBoard.push row
    totalScore := totalScore + score
  return (newBoard, totalScore)

def Board.reverseRows (b : Board) : Board := b.map Array.reverse

def Board.transpose (b : Board) : Board := Id.run do
  let mut result : Board := #[]
  for j in [0:4] do
    let mut row : Array Nat := #[]
    for i in [0:4] do
      row := row.push (b.get i j)
    result := result.push row
  return result

def Board.moveRight (b : Board) : Board × Nat :=
  let (b', s) := b.reverseRows.moveLeft
  (b'.reverseRows, s)

def Board.moveUp (b : Board) : Board × Nat :=
  let (b', s) := b.transpose.moveLeft
  (b'.transpose, s)

def Board.moveDown (b : Board) : Board × Nat :=
  let (b', s) := b.transpose.moveRight
  (b'.transpose, s)

def Board.equal (b1 b2 : Board) : Bool := Id.run do
  for i in [0:4] do
    for j in [0:4] do
      if b1.get i j ≠ b2.get i j then return false
  return true

def Board.isGameOver (b : Board) : Bool := Id.run do
  if !b.emptyCells.isEmpty then return false
  for i in [0:4] do
    for j in [0:4] do
      let v := b.get i j
      if Nat.blt (i + 1) 4 then
        if b.get (i + 1) j = v then return false
      if Nat.blt (j + 1) 4 then
        if b.get i (j + 1) = v then return false
  return true

def Board.hasWon (b : Board) : Bool := Id.run do
  for i in [0:4] do
    for j in [0:4] do
      if b.get i j ≥ 2048 then return true
  return false

/- Colors taken from the official 2048 game by Gabriele Cirulli. -/

def tileBackgroundColor : Nat → String
  | 0 => "rgba(238, 228, 218, 0.35)"
  | 2 => "#eee4da"
  | 4 => "#ede0c8"
  | 8 => "#f2b179"
  | 16 => "#f59563"
  | 32 => "#f67c5f"
  | 64 => "#f65e3b"
  | 128 => "#edcf72"
  | 256 => "#edcc61"
  | 512 => "#edc850"
  | 1024 => "#edc53f"
  | 2048 => "#edc22e"
  | _ => "#3c3a32"

def tileTextColor (v : Nat) : String :=
  if v ≤ 4 then "#776e65" else "#f9f6f2"

def tileFontSize (v : Nat) : String :=
  if (v < 100) then "55px"
  else if (v < 1000) then "45px"
  else if (v < 10000) then "35px"
  else "30px"

def tileStyle (v : Nat) : Json := mkStyle [
  ("width", "100px"),
  ("height", "100px"),
  ("lineHeight", "100px"),
  ("background", tileBackgroundColor v),
  ("color", tileTextColor v),
  ("fontSize", tileFontSize v),
  ("fontWeight", "bold"),
  ("borderRadius", "3px"),
  ("textAlign", "center"),
  ("fontFamily", "'Clear Sans', 'Helvetica Neue', Arial, sans-serif")
]

def rowStyle : Json := mkStyle [
  ("display", "flex"),
  ("gap", "15px"),
  ("marginBottom", "15px")
]

def lastRowStyle : Json := mkStyle [
  ("display", "flex"),
  ("gap", "15px")
]

def boardStyle : Json := mkStyle [
  ("background", "#bbada0"),
  ("padding", "15px"),
  ("borderRadius", "6px"),
  ("display", "inline-block")
]

def containerStyle : Json := mkStyle [
  ("width", "500px"),
  ("padding", "25px"),
  ("fontFamily", "'Clear Sans', 'Helvetica Neue', Arial, sans-serif"),
  ("background", "#faf8ef"),
  ("borderRadius", "6px"),
  ("color", "#776e65")
]

def titleStyle : Json := mkStyle [
  ("color", "#776e65"),
  ("fontSize", "80px"),
  ("fontWeight", "bold"),
  ("margin", "0"),
  ("lineHeight", "80px")
]

def headerStyle : Json := mkStyle [
  ("display", "flex"),
  ("justifyContent", "space-between"),
  ("alignItems", "center"),
  ("marginBottom", "20px")
]

def scoreBoxStyle : Json := mkStyle [
  ("background", "#bbada0"),
  ("padding", "10px 25px"),
  ("borderRadius", "3px"),
  ("color", "white"),
  ("textAlign", "center"),
  ("minWidth", "60px"),
  ("lineHeight", "1")
]

def scoreLabelStyle : Json := mkStyle [
  ("fontSize", "13px"),
  ("color", "#eee4da"),
  ("textTransform", "uppercase"),
  ("fontWeight", "bold"),
  ("marginBottom", "4px")
]

def scoreValueStyle : Json := mkStyle [
  ("fontSize", "25px"),
  ("fontWeight", "bold"),
  ("color", "white")
]

def instructionStyle : Json := mkStyle [
  ("color", "#776e65"),
  ("fontSize", "14px"),
  ("marginBottom", "15px"),
  ("marginTop", "0")
]

def gameOverStyle : Json := mkStyle [
  ("color", "#776e65"),
  ("fontSize", "30px"),
  ("fontWeight", "bold"),
  ("textAlign", "center"),
  ("marginTop", "10px"),
  ("marginBottom", "0")
]

def arrowButtonStyle : Json := mkStyle [
  ("width", "60px"),
  ("height", "60px"),
  ("fontSize", "30px"),
  ("background", "#8f7a66"),
  ("color", "#f9f6f2"),
  ("border", "none"),
  ("borderRadius", "3px"),
  ("cursor", "pointer"),
  ("fontWeight", "bold"),
  ("margin", "5px")
]

def newGameButtonStyle : Json := mkStyle [
  ("padding", "10px 20px"),
  ("fontSize", "18px"),
  ("background", "#8f7a66"),
  ("color", "#f9f6f2"),
  ("border", "none"),
  ("borderRadius", "3px"),
  ("cursor", "pointer"),
  ("fontWeight", "bold"),
  ("marginTop", "15px")
]

def controlsStyle : Json := mkStyle [
  ("marginTop", "20px"),
  ("textAlign", "center")
]

def arrowRowStyle : Json := mkStyle [
  ("display", "flex"),
  ("justifyContent", "center")
]

def centerStyle : Json := mkStyle [
  ("textAlign", "center")
]

/- Rendering -/

def renderTile (v : Nat) : Html :=
  <div style={tileStyle v}>
    {if v = 0 then (<span></span> : Html) else (.text s!"{v}" : Html)}
  </div>

def renderRow (b : Board) (i : Nat) (isLast : Bool) : Html :=
  .element "div" #[("style", if isLast then lastRowStyle else rowStyle)] <|
    (Array.range 4).map fun j => renderTile (b.get i j)

def renderBoard (b : Board) : Html :=
  .element "div" #[("style", boardStyle)] <|
    (Array.range 4).map fun i => renderRow b i (i = 3)

def initialBoard : BaseIO Board := do
  let b1 ← Board.empty.addRandomTile
  b1.addRandomTile

/- The main widget: 2048 game with on-screen arrow buttons. -/

def game2048 : BaseIO Html := do
  let board : IO.Ref Board ← IO.mkRef (← initialBoard)
  let score : IO.Ref Nat ← IO.mkRef 0
  let gameOver : IO.Ref Bool ← IO.mkRef false
  let won : IO.Ref Bool ← IO.mkRef false

  let mkMoveHandler (move : Board → Board × Nat) : Unit → RequestM Unit :=
    fun _ => do
      let isOver ← gameOver.get
      if !isOver then
        let current ← board.get
        let (newB, delta) := move current
        if !current.equal newB then
          let withNew ← newB.addRandomTile
          board.set withNew
          score.modify (· + delta)
          if withNew.hasWon then won.set true
          if withNew.isGameOver then gameOver.set true

  let resetHandler : Unit → RequestM Unit :=
    fun _ => do
      board.set (← initialBoard)
      score.set 0
      gameOver.set false
      won.set false

  createStatefulHtml <| do
    let currentBoard ← board.get
    let currentScore ← score.get
    let isOver ← gameOver.get
    let hasWon ← won.get
    return (
      <div style={containerStyle}>
        <div style={headerStyle}>
          <h1 style={titleStyle}>{.text "2048"}</h1>
          <div style={scoreBoxStyle}>
            <div style={scoreLabelStyle}>{.text "Score"}</div>
            <div style={scoreValueStyle}>{.text s!"{currentScore}"}</div>
          </div>
        </div>
        <p style={instructionStyle}>
          {.text "Join the tiles, get to 2048! Use the on-screen arrow buttons below."}
        </p>
        {renderBoard currentBoard}
        {if isOver then (<p style={gameOverStyle}>{.text "Game Over!"}</p> : Html)
         else if hasWon then (<p style={gameOverStyle}>{.text "You Win!"}</p> : Html)
         else (<span></span> : Html)}
        <div style={controlsStyle}>
          <div style={arrowRowStyle}>
            <Button style={arrowButtonStyle}
                onClick={← asEventRef (mkMoveHandler Board.moveUp)}>
              {.text "↑"}
            </Button>
          </div>
          <div style={arrowRowStyle}>
            <Button style={arrowButtonStyle}
                onClick={← asEventRef (mkMoveHandler Board.moveLeft)}>
              {.text "←"}
            </Button>
            <Button style={arrowButtonStyle}
                onClick={← asEventRef (mkMoveHandler Board.moveDown)}>
              {.text "↓"}
            </Button>
            <Button style={arrowButtonStyle}
                onClick={← asEventRef (mkMoveHandler Board.moveRight)}>
              {.text "→"}
            </Button>
          </div>
        </div>
        <div style={centerStyle}>
          <Button style={newGameButtonStyle}
              onClick={← asEventRef resetHandler}>
            {.text "New Game"}
          </Button>
        </div>
      </div>
    )

#html game2048
