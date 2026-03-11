import React from "react";
import { RpcPtr, DocumentPosition } from "@leanprover/infoview";
interface ButtonProps {
    onClick: RpcPtr<'RequestMUnit'>;
    style?: React.CSSProperties;
}
interface HoverProps {
    onMouseEnter: RpcPtr<'RequestMUnit'>;
    onMouseLeave: RpcPtr<'RequestMUnit'>;
    style?: React.CSSProperties;
}
interface TextInputProps {
    placeholder: string;
    onChange: RpcPtr<'StringToRequestMUnit'>;
    value: string;
    style?: React.CSSProperties;
}
interface NumberInputProps {
    placeholder: string;
    onChange: RpcPtr<'NumberToRequestMUnit'>;
    value?: number;
    max?: number;
    min?: number;
    width?: number;
    style?: React.CSSProperties;
}
interface CheckboxProps {
    checked: boolean;
    onChange: RpcPtr<'BooleanToRequestMUnit'>;
    style?: React.CSSProperties;
}
interface DropdownProps {
    options: string[];
    selectedIndex?: number;
    onChange: RpcPtr<'NumberToRequestMUnit'>;
    style?: React.CSSProperties;
}
interface RadioButtonProps {
    options: string[];
    selectedIndex?: number;
    onChange: RpcPtr<'NumberToRequestMUnit'>;
    name: string;
    style?: React.CSSProperties;
}
interface SliderProps {
    value: number;
    onChange: RpcPtr<'NumberToRequestMUnit'>;
    min?: number;
    max?: number;
    style?: React.CSSProperties;
}
interface StatefulHtmlProps {
    html: RpcPtr<'RequestMHtml'>;
    pos: DocumentPosition;
}
export declare function Button(props: React.PropsWithChildren<ButtonProps>): JSX.Element;
export declare function Hover(props: React.PropsWithChildren<HoverProps>): JSX.Element;
export declare function TextInput(props: TextInputProps): JSX.Element;
export declare function NumberInput(props: NumberInputProps): JSX.Element;
export declare function Checkbox(props: CheckboxProps): JSX.Element;
export declare function Dropdown(props: DropdownProps): JSX.Element;
export declare function RadioButton(props: RadioButtonProps): JSX.Element;
export declare function Slider(props: SliderProps): JSX.Element;
export default function StatefulHtml(props: StatefulHtmlProps): JSX.Element;
export {};
