module

public import Lean.Server.Requests
public import ProofWidgets

public meta section

open Lean ProofWidgets Server Jsx Elab Command

abbrev UnitToRequestMUnit := Unit → RequestM (RequestTask Unit)
instance : TypeName UnitToRequestMUnit := unsafe .mk UnitToRequestMUnit ``UnitToRequestMUnit

abbrev RequestMHtml := RequestM Html
instance : TypeName RequestMHtml := unsafe .mk RequestMHtml ``RequestMHtml

abbrev StringToRequestMUnit := String → RequestM (RequestTask Unit)
instance : TypeName StringToRequestMUnit := unsafe .mk StringToRequestMUnit ``StringToRequestMUnit

abbrev NatToRequestMUnit := Nat → RequestM (RequestTask Unit)
instance : TypeName NatToRequestMUnit := unsafe .mk NatToRequestMUnit ``NatToRequestMUnit

abbrev BooleanToRequestMUnit := Bool → RequestM (RequestTask Unit)
instance : TypeName BooleanToRequestMUnit := unsafe .mk BooleanToRequestMUnit ``BooleanToRequestMUnit

abbrev NumberToRequestMUnit := Nat → RequestM (RequestTask Unit)
instance : TypeName NumberToRequestMUnit := unsafe .mk NumberToRequestMUnit ``NumberToRequestMUnit

deriving instance ToJson, FromJson for PUnit

def asEventRef {α β : Type} (event : α → RequestM β) : BaseIO (WithRpcRef (α → RequestM (RequestTask β))) :=
  WithRpcRef.mk fun a ↦ RequestM.asTask (event a)

structure StatefulHtmlProps where
  html : WithRpcRef RequestMHtml
deriving RpcEncodable

@[server_rpc_method]
def StatefulHtml.rpc (props : StatefulHtmlProps) : RequestM (RequestTask Html) := RequestM.asTask do
  props.html.val

@[widget_module]
def StatefulHtml : Component StatefulHtmlProps where
  javascript := include_str ".." / ".lake" / "build" / "js" / "statefulHtml.js"
  «export» := "default"

def createStatefulHtml (html : RequestM Html) : BaseIO Html := do
  return <StatefulHtml html={← WithRpcRef.mk html} />


structure ButtonProps where
  onClick : WithRpcRef (Unit → RequestM (RequestTask Unit))
  style : Option Json := none
deriving RpcEncodable

@[server_rpc_method]
def Button.rpc (props : ButtonProps) : RequestM (RequestTask Unit) := do
  props.onClick.val ()

@[widget_module]
def Button : Component ButtonProps where
  javascript := include_str ".." / ".lake" / "build" / "js" / "statefulHtml.js"
  «export» := "Button"

structure HoverProps where
  onMouseEnter : WithRpcRef (Unit → RequestM (RequestTask Unit))
  onMouseLeave : WithRpcRef (Unit → RequestM (RequestTask Unit))
  style : Option Json := none
deriving RpcEncodable

@[server_rpc_method]
def Hover.onMouseEnter.rpc (props : HoverProps) : RequestM (RequestTask Unit) := do
  props.onMouseEnter.val ()

@[server_rpc_method]
def Hover.onMouseLeave.rpc (props : HoverProps) : RequestM (RequestTask Unit) := do
  props.onMouseLeave.val ()

@[widget_module]
def Hover : Component HoverProps where
  javascript := include_str ".." / ".lake" / "build" / "js" / "statefulHtml.js"
  «export» := "Hover"

structure TextInputProps where
  placeholder : String := ""
  onChange : WithRpcRef (String → RequestM (RequestTask Unit))
  value : String := ""
  style : Option Json := none
deriving RpcEncodable

@[server_rpc_method]
def TextInput.rpc (props : TextInputProps) : RequestM (RequestTask Unit) := do
  props.onChange.val props.value

@[widget_module]
def TextInput : Component TextInputProps where
  javascript := include_str ".." / ".lake" / "build" / "js" / "statefulHtml.js"
  «export» := "TextInput"

structure TextSubmitBoxProps where
  placeholder : String := ""
  value : String := ""
  onSubmit : WithRpcRef (String → RequestM (RequestTask Unit))
  textInputStyle : Option Json := none
  submitButtonStyle : Option Json := none
deriving RpcEncodable

@[server_rpc_method]
def TextSubmitBox.rpc (props : TextSubmitBoxProps) : RequestM (RequestTask Unit) := do
  props.onSubmit.val props.value

@[widget_module]
def TextSubmitBox : Component TextSubmitBoxProps where
  javascript := include_str ".." / ".lake" / "build" / "js" / "statefulHtml.js"
  «export» := "TextSubmitBox"

structure NumberInputProps where
  placeholder : String := ""
  onChange : WithRpcRef (Nat → RequestM (RequestTask Unit))
  max : Option Nat := none
  min : Option Nat := none
  value : Option Nat := none
  width: Option Nat := none
  style : Option Json := none
deriving RpcEncodable

@[server_rpc_method]
def NumberInput.rpc (props : NumberInputProps) : RequestM (RequestTask Unit) := do
  match props.value with
  | some n => props.onChange.val n
  | none => RequestM.asTask do pure ()

@[widget_module]
def NumberInput : Component NumberInputProps where
  javascript := include_str ".." / ".lake" / "build" / "js" / "statefulHtml.js"
  «export» := "NumberInput"

structure CheckboxProps where
  checked : Bool := false
  onChange : WithRpcRef (Bool → RequestM (RequestTask Unit))
  style : Option Json := none
deriving RpcEncodable

@[server_rpc_method]
def Checkbox.rpc (props : CheckboxProps) : RequestM (RequestTask Unit) := do
  props.onChange.val props.checked

@[widget_module]
def Checkbox : Component CheckboxProps where
  javascript := include_str ".." / ".lake" / "build" / "js" / "statefulHtml.js"
  «export» := "Checkbox"

structure DropdownProps where
  options : Array String
  selectedIndex : Option Nat := none
  onChange : WithRpcRef (Nat → RequestM (RequestTask Unit))
  style : Option Json := none
deriving RpcEncodable

@[server_rpc_method]
def Dropdown.rpc (props : DropdownProps) : RequestM (RequestTask Unit) := do
  match props.selectedIndex with
  | some idx => props.onChange.val idx
  | none => props.onChange.val 0

@[widget_module]
def Dropdown : Component DropdownProps where
  javascript := include_str ".." / ".lake" / "build" / "js" / "statefulHtml.js"
  «export» := "Dropdown"

structure RadioButtonProps where
  options : Array String
  selectedIndex : Option Nat := none
  onChange : WithRpcRef (Nat → RequestM (RequestTask Unit))
  name : String
  style : Option Json := none
deriving RpcEncodable

@[server_rpc_method]
def RadioButton.rpc (props : RadioButtonProps) : RequestM (RequestTask Unit) := do
  match props.selectedIndex with
  | some idx => props.onChange.val idx
  | none => props.onChange.val 0

@[widget_module]
def RadioButton : Component RadioButtonProps where
  javascript := include_str ".." / ".lake" / "build" / "js" / "statefulHtml.js"
  «export» := "RadioButton"

structure SliderProps where
  value : Nat := 0
  onChange : WithRpcRef (Nat → RequestM (RequestTask Unit))
  min : Option Nat := none
  max : Option Nat := none
  style : Option Json := none
deriving RpcEncodable

@[server_rpc_method]
def Slider.rpc (props : SliderProps) : RequestM (RequestTask Unit) := do
  props.onChange.val props.value

@[widget_module]
def Slider : Component SliderProps where
  javascript := include_str ".." / ".lake" / "build" / "js" / "statefulHtml.js"
  «export» := "Slider"
