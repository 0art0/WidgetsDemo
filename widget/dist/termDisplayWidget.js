import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
export default function TermDisplayWidget(props) {
    return (_jsxs("div", { style: {
            maxWidth: "500px",
            margin: "40px auto",
            padding: "24px",
            background: "#1e1e2f",
            borderRadius: "12px",
            color: "#f5f5f5",
            fontFamily: "Consolas, monospace",
            boxShadow: "0 8px 20px rgba(0, 0, 0, 0.2)",
            transition: "transform 0.3s"
        }, children: [_jsxs("div", { style: { marginBottom: "16px", borderBottom: "1px solid #444", paddingBottom: "12px" }, children: [_jsx("h2", { style: { fontSize: "1.75rem", margin: 0, color: "#66d9ef" }, children: props.term }), _jsx("p", { style: { fontSize: "1rem", margin: "8px 0 0", color: "#9cdcfe" }, children: _jsx("em", { children: props.type }) })] }), _jsx("div", { style: { fontSize: "0.95rem", color: "#ccc" }, children: _jsxs("p", { children: [_jsx("strong", { children: "Definition:" }), " The term `", _jsx("span", { style: { color: "#ffd700" }, children: props.term }), "` is a `", _jsx("span", { style: { color: "#98c379" }, children: props.type }), "`."] }) })] }));
}
