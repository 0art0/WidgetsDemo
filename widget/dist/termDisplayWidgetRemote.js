import { Fragment as _Fragment, jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { EnvPosContext, importWidgetModule, mapRpcError, useAsyncPersistent, useRpcSession } from '@leanprover/infoview';
// import HtmlDisplay, {Html} from "./htmlDisplay"
// Code for rendering HTML from ProofWidgets
/*
Copyright (c) 2022 E.W.Ayers. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: E.W.Ayers, Wojciech Nawrocki
*/
import * as React from 'react';
/**
 * Render a HTML tree into JSX, resolving any dynamic imports corresponding to `component`s along
 * the way.
 *
 * This guarantees that the resulting React tree is exactly as written down in Lean. In particular,
 * there are no extraneous {@link DynamicComponent} nodes which works better with some libraries
 * that directly inspect the children nodes.
 */
export async function renderHtml(rs, pos, html) {
    if ('text' in html) {
        return _jsx(_Fragment, { children: html.text });
    }
    else if ('element' in html) {
        const [tag, attrsList, cs] = html.element;
        const attrs = {};
        for (const [k, v] of attrsList) {
            attrs[k] = v;
        }
        const children = await Promise.all(cs.map(async (html) => await renderHtml(rs, pos, html)));
        if (tag === "hr") {
            // React is greatly concerned by <hr/>s having children.
            return _jsx("hr", {});
        }
        else if (children.length === 0) {
            return React.createElement(tag, attrs);
        }
        else {
            return React.createElement(tag, attrs, children);
        }
    }
    else if ('component' in html) {
        const [hash, export_, props, cs] = html.component;
        const children = await Promise.all(cs.map(async (html) => await renderHtml(rs, pos, html)));
        const dynProps = { ...props, pos };
        const mod = await importWidgetModule(rs, pos, hash);
        if (!(export_ in mod))
            throw new Error(`Module '${hash}' does not export '${export_}'`);
        if (children.length === 0) {
            return React.createElement(mod[export_], dynProps);
        }
        else {
            return React.createElement(mod[export_], dynProps, children);
        }
    }
    else {
        return _jsxs("span", { className: "red", children: ["Unknown HTML variant: ", JSON.stringify(html)] });
    }
}
export function HtmlDisplay({ html }) {
    const rs = useRpcSession();
    const pos = React.useContext(EnvPosContext);
    const state = useAsyncPersistent(() => renderHtml(rs, pos, html), [rs, pos, html]);
    if (state.state === 'resolved')
        return state.value;
    else if (state.state === 'rejected')
        return _jsxs("span", { className: "red", children: ["Error rendering HTML: ", mapRpcError(state.error).message] });
    return _jsx(_Fragment, {});
}
export default function TermDisplayWidgetRemote(props) {
    const rs = useRpcSession();
    const st = useAsyncPersistent(async () => {
        const ret = await rs.call('TermDisplayWidgetRemote.rpc', { name: props.name, env: props.env });
        return ret;
    }, [rs, props.name, props.env]);
    if (st.state === 'loading')
        return _jsx(_Fragment, { children: "Loading.." });
    else if (st.state === 'rejected')
        return _jsxs(_Fragment, { children: ["Error: ", mapRpcError(st.error).message] });
    else
        return _jsx(HtmlDisplay, { html: st.value });
}
