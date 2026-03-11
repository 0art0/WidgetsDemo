import { jsx as _jsx, jsxs as _jsxs, Fragment as _Fragment } from "react/jsx-runtime";
import React from "react";
import { useRpcSession } from "@leanprover/infoview";
import { renderHtml } from "./htmlDisplay";
function updateInteractionState(state, interaction) {
    console.log("Interaction:", interaction);
    return [...state, interaction];
}
const InteractionDispatchContext = React.createContext(null);
export function Button(props) {
    const rs = useRpcSession();
    const interactionDispatch = React.useContext(InteractionDispatchContext);
    // const [renderedContent, setRenderedContent] = React.useState<JSX.Element>(<></>)
    // React.useEffect(() => {
    //   renderHtml(rs, props.pos, props.content).then(setRenderedContent)
    // }, [props.content, props.pos, rs])
    const onClick = async () => {
        await rs.call("Button.rpc", { onClick: props.onClick, style: props.style })
            .then(() => {
            interactionDispatch?.({ type: 'Button', props: { onClick: props.onClick, style: props.style } });
        })
            .catch((e) => {
            console.error("Error clicking button:", e);
        });
    };
    return _jsx("button", { onClick: onClick, style: props.style, children: props.children });
}
export function Hover(props) {
    const rs = useRpcSession();
    const interactionDispatch = React.useContext(InteractionDispatchContext);
    const hoverProps = {
        onMouseEnter: props.onMouseEnter,
        onMouseLeave: props.onMouseLeave,
        style: props.style
    };
    const onMouseEnter = async () => {
        await rs.call("Hover.onMouseEnter.rpc", hoverProps)
            .then(() => {
            interactionDispatch?.({ type: 'Hover', props: hoverProps });
        })
            .catch((e) => {
            console.error("Error on mouse enter:", e);
        });
    };
    const onMouseLeave = async () => {
        await rs.call("Hover.onMouseLeave.rpc", hoverProps)
            .then(() => {
            interactionDispatch?.({ type: 'Hover', props: hoverProps });
        })
            .catch((e) => {
            console.error("Error on mouse leave:", e);
        });
    };
    return (_jsx("div", { onMouseEnter: onMouseEnter, onMouseLeave: onMouseLeave, style: props.style, children: props.children }));
}
export function TextInput(props) {
    const rs = useRpcSession();
    const interactionDispatch = React.useContext(InteractionDispatchContext);
    const onChange = async (e) => {
        await rs.call("TextInput.rpc", { ...props, value: e.target.value }).then(() => {
            interactionDispatch?.({ type: 'TextInput', props: { ...props, value: e.target.value } });
        }).catch((e) => {
            console.error("Error changing text input:", e);
        });
    };
    return (_jsx("div", { children: _jsx("input", { type: "text", value: props.value, placeholder: props.placeholder, onChange: onChange, style: props.style }) }));
}
export function NumberInput(props) {
    const rs = useRpcSession();
    const interactionDispatch = React.useContext(InteractionDispatchContext);
    const onChange = async (e) => {
        const newValue = Number(e.target.value);
        await rs.call("NumberInput.rpc", { ...props, value: newValue }).then(() => {
            interactionDispatch?.({ type: 'NumberInput', props: { ...props, value: newValue } });
        }).catch((e) => {
            console.error("Error changing number input:", e);
        });
    };
    return (_jsx("div", { children: _jsx("input", { type: "number", value: props.value ?? undefined, placeholder: props.placeholder, onChange: onChange, max: props.max, min: props.min, width: props.width, style: props.style }) }));
}
export function Checkbox(props) {
    const rs = useRpcSession();
    const interactionDispatch = React.useContext(InteractionDispatchContext);
    const onChange = async (e) => {
        const newChecked = e.target.checked;
        await rs.call("Checkbox.rpc", { ...props, checked: newChecked }).then(() => {
            interactionDispatch?.({ type: 'CheckBox', props: { ...props, checked: newChecked } });
        }).catch((e) => {
            console.error("Error changing checkbox:", e);
        });
    };
    return (_jsx("input", { type: "checkbox", checked: props.checked, onChange: onChange, style: props.style }));
}
export function Dropdown(props) {
    const rs = useRpcSession();
    const interactionDispatch = React.useContext(InteractionDispatchContext);
    const onChange = async (e) => {
        const newIndex = Number(e.target.value);
        await rs.call("Dropdown.rpc", { ...props, selectedIndex: newIndex }).then(() => {
            interactionDispatch?.({ type: 'Dropdown', props: { ...props, selectedIndex: newIndex } });
        }).catch((e) => {
            console.error("Error changing dropdown:", e);
        });
    };
    return (_jsx("select", { value: props.selectedIndex ?? 0, onChange: onChange, style: props.style, children: props.options.map((option, index) => (_jsx("option", { value: index, children: option }, index))) }));
}
export function RadioButton(props) {
    const rs = useRpcSession();
    const interactionDispatch = React.useContext(InteractionDispatchContext);
    const onChange = async (e) => {
        const newIndex = Number(e.target.value);
        await rs.call("RadioButton.rpc", { ...props, selectedIndex: newIndex }).then(() => {
            interactionDispatch?.({ type: 'RadioButton', props: { ...props, selectedIndex: newIndex } });
        }).catch((e) => {
            console.error("Error changing radio button:", e);
        });
    };
    return (_jsx("div", { style: props.style, children: props.options.map((option, index) => (_jsxs("label", { style: { display: 'block' }, children: [_jsx("input", { type: "radio", name: props.name, value: index, checked: (props.selectedIndex ?? 0) === index, onChange: onChange }), option] }, index))) }));
}
export function Slider(props) {
    const rs = useRpcSession();
    const interactionDispatch = React.useContext(InteractionDispatchContext);
    const onChange = async (e) => {
        const newValue = Number(e.target.value);
        await rs.call("Slider.rpc", { ...props, value: newValue }).then(() => {
            interactionDispatch?.({ type: 'Slider', props: { ...props, value: newValue } });
        }).catch((e) => {
            console.error("Error changing slider:", e);
        });
    };
    return (_jsx("input", { type: "range", value: props.value, onChange: onChange, min: props.min, max: props.max, style: props.style }));
}
export default function StatefulHtml(props) {
    const rs = useRpcSession();
    const [renderedContent, setRenderedContent] = React.useState(_jsx(_Fragment, {}));
    const [interactionState, dispatchInteraction] = React.useReducer(updateInteractionState, []);
    React.useEffect(() => {
        rs.call("StatefulHtml.rpc", props)
            .then(async (result) => {
            setRenderedContent(await renderHtml(rs, props.pos, result));
        })
            .catch((e) => {
            console.error("Error fetching `StatefulHtml`:", e);
        });
    }, [interactionState, rs]);
    return (_jsx(InteractionDispatchContext.Provider, { value: dispatchInteraction, children: renderedContent }));
}
