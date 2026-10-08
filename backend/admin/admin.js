(() => {
  const TOKEN_KEY = "ddrtz_moderation_token";
  const authPanel = document.getElementById("auth-panel");
  const workspace = document.getElementById("workspace");
  const authForm = document.getElementById("auth-form");
  const authStatus = document.getElementById("auth-status");
  const tokenInput = document.getElementById("admin-token");
  const signOut = document.getElementById("sign-out");
  const status = document.getElementById("status");
  const head = document.getElementById("table-head");
  const rows = document.getElementById("rows");
  let token = sessionStorage.getItem(TOKEN_KEY) || "";
  let view = "open";

  function setStatus(message) {
    status.textContent = message;
  }

  async function api(path, options = {}) {
    const response = await fetch(path, {
      ...options,
      headers: {
        "X-Admin-Token": token,
        ...(options.body ? { "Content-Type": "application/json" } : {}),
        ...(options.headers || {}),
      },
    });
    const body = await response.json().catch(() => ({}));
    if (!response.ok) {
      if (response.status === 401) disconnect();
      throw new Error(body.error || `request_failed_${response.status}`);
    }
    return body;
  }

  function cell(row, value, className = "") {
    const item = document.createElement("td");
    item.textContent = value == null ? "-" : String(value);
    if (className) item.className = className;
    row.append(item);
    return item;
  }

  function button(label, action, className = "") {
    const item = document.createElement("button");
    item.type = "button";
    item.textContent = label;
    if (className) item.className = className;
    item.addEventListener("click", action);
    return item;
  }

  function dateLabel(value) {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? "-" : date.toLocaleString();
  }

  async function load() {
    if (!token) return;
    rows.replaceChildren();
    head.replaceChildren();
    setStatus("Loading…");
    try {
      if (view === "hidden") {
        const result = await api("/v1/admin/profiles/hidden");
        makeHeader(["Public name", "Hidden since", "Action"]);
        for (const profile of result.profiles) {
          const row = document.createElement("tr");
          cell(row, profile.displayName);
          cell(row, dateLabel(profile.moderatedAt));
          const actions = cell(row, "", "actions");
          actions.append(button("Restore profile", async () => runAction(
            `/v1/admin/profiles/${encodeURIComponent(profile.targetId)}/restore`,
            { method: "POST" }, "Profile restored.")));
          rows.append(row);
        }
        setStatus(`${result.profiles.length} hidden profile(s).`);
      } else {
        const result = await api(`/v1/admin/reports?status=${view}`);
        makeHeader(["Name / route", "Reason", "Reports", "Submitted", "Review", "Actions"]);
        for (const report of result.reports) {
          const row = document.createElement("tr");
          cell(row, `${report.displayName} · ${report.routeId}`);
          cell(row, report.reason);
          cell(row, report.reportCount);
          cell(row, dateLabel(report.createdAt));
          cell(row, report.status === "open" ? "Open" : `${report.status}: ${report.action || "-"}`);
          const actions = cell(row, "", "actions");
          if (report.status === "open") {
            actions.append(button("Dismiss", async () => runAction(
              `/v1/admin/reports/${report.reportId}/resolve`,
              { method: "POST", body: JSON.stringify({ action: "dismiss" }) }, "Report dismissed.")));
            actions.append(button("Hide profile", async () => {
              if (!window.confirm(`Hide ${report.displayName} from World and Friends boards?`)) return;
              await runAction(`/v1/admin/reports/${report.reportId}/resolve`,
                { method: "POST", body: JSON.stringify({ action: "hide_profile" }) }, "Profile hidden from public boards.");
            }, "danger"));
          }
          rows.append(row);
        }
        setStatus(`${result.reports.length} report(s). Names and scores are not automatically treated as verified.`);
      }
      if (!rows.childElementCount) {
        const row = document.createElement("tr");
        cell(row, "Nothing to review.", "empty").colSpan = 6;
        rows.append(row);
      }
    } catch (error) {
      setStatus(`Could not load moderation data: ${error.message}`);
    }
  }

  function makeHeader(labels) {
    const row = document.createElement("tr");
    for (const label of labels) {
      const item = document.createElement("th");
      item.scope = "col";
      item.textContent = label;
      row.append(item);
    }
    head.append(row);
  }

  async function runAction(path, options, successMessage) {
    try {
      await api(path, options);
      setStatus(successMessage);
      await load();
    } catch (error) {
      setStatus(`Action failed: ${error.message}`);
    }
  }

  function connect() {
    authPanel.hidden = !token;
    workspace.hidden = !token;
    signOut.hidden = !token;
    if (token) void load();
  }

  function disconnect() {
    token = "";
    sessionStorage.removeItem(TOKEN_KEY);
    connect();
  }

  authForm.addEventListener("submit", async (event) => {
    event.preventDefault();
    token = tokenInput.value.trim();
    try {
      await api("/v1/admin/reports?status=open");
      sessionStorage.setItem(TOKEN_KEY, token);
      tokenInput.value = "";
      connect();
    } catch (error) {
      token = "";
      authStatus.textContent = `Access failed: ${error.message}`;
    }
  });

  document.querySelectorAll("nav [data-view]").forEach((item) => {
    item.addEventListener("click", () => {
      view = item.dataset.view;
      document.querySelectorAll("nav [data-view]").forEach((tab) => {
        tab.classList.toggle("selected", tab === item);
      });
      void load();
    });
  });
  document.getElementById("refresh").addEventListener("click", () => void load());
  signOut.addEventListener("click", disconnect);
  if (!token) status.textContent = "";
  connect();
})();
