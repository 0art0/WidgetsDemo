import { DocumentPosition, RpcSessionAtPos } from '@leanprover/infoview';
export type Html = {
    element: [string, [string, any][], Html[]];
} | {
    text: string;
} | {
    component: [string, string, any, Html[]];
};
/**
 * Render a HTML tree into JSX, resolving any dynamic imports corresponding to `component`s along
 * the way.
 *
 * This guarantees that the resulting React tree is exactly as written down in Lean. In particular,
 * there are no extraneous {@link DynamicComponent} nodes which works better with some libraries
 * that directly inspect the children nodes.
 */
export declare function renderHtml(rs: RpcSessionAtPos, pos: DocumentPosition, html: Html): Promise<JSX.Element>;
export default function HtmlDisplay({ html }: {
    html: Html;
}): JSX.Element;
