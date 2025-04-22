import * as React from "react";
import { Markdown } from "@leanprover/infoview"

interface TermDisplayWidgetProps {
    term: String,
    type: String
}

export default function TermDisplayWidget(props: TermDisplayWidgetProps) {
    return (
        <div
          style={{
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
          <div style={{ marginBottom: "16px", borderBottom: "1px solid #444", paddingBottom: "12px" }}>
            <h2 style={{ fontSize: "1.75rem", margin: 0, color: "#66d9ef" }}>{props.term}</h2>
            <p style={{ fontSize: "1rem", margin: "8px 0 0", color: "#9cdcfe" }}>
              <em>{props.type}</em>
            </p>
          </div>
          <div style={{ fontSize: "0.95rem", color: "#ccc" }}>
            <p>
              <strong>Definition:</strong> The term `<span style={{ color: "#ffd700" }}>{props.term}</span>` is a `<span style={{ color: "#98c379" }}>{props.type}</span>`.
            </p>
          </div>
        </div>
      );
}