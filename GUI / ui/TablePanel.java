package ui;

import app.DB;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.BorderLayout;
import java.sql.*;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Vector;

public class TablePanel extends JPanel {
    private final String table;
    private JTable jtable;
    private java.util.List<String> pk = new ArrayList<>();

    public TablePanel(String table) {
        this.table = table;
        setLayout(new BorderLayout());

        jtable = new JTable();
        add(new JScrollPane(jtable), BorderLayout.CENTER);

        JPanel top = new JPanel();
        JButton r = new JButton("Refresh");
        JButton i = new JButton("Insert");
        JButton u = new JButton("Update");
        JButton d = new JButton("Delete");

        top.add(r);
        top.add(i);
        top.add(u);
        top.add(d);
        add(top, BorderLayout.NORTH);

        r.addActionListener(e -> load());
        i.addActionListener(e -> insert());
        u.addActionListener(e -> update());
        d.addActionListener(e -> delete());

        load();
    }

    private void load() {
        try (Connection c = DB.get();
             Statement s = c.createStatement();
             ResultSet rs = s.executeQuery("SELECT * FROM " + table + " LIMIT 500")) {

            pk.clear();
            DatabaseMetaData md = c.getMetaData();
            try (ResultSet pkrs = md.getPrimaryKeys(c.getCatalog(), null, table)) {
                while (pkrs.next()) pk.add(pkrs.getString("COLUMN_NAME"));
            }

            jtable.setModel(build(rs));

        } catch (Exception e) {
            JOptionPane.showMessageDialog(this, e.getMessage());
        }
    }

    private DefaultTableModel build(ResultSet rs) throws SQLException {
        ResultSetMetaData m = rs.getMetaData();
        Vector<String> cols = new Vector<>();
        for (int i = 1; i <= m.getColumnCount(); i++) cols.add(m.getColumnName(i));

        Vector<Vector<Object>> data = new Vector<>();
        while (rs.next()) {
            Vector<Object> row = new Vector<>();
            for (int i = 1; i <= m.getColumnCount(); i++) row.add(rs.getObject(i));
            data.add(row);
        }

        return new DefaultTableModel(data, cols) {
            public boolean isCellEditable(int r, int c) { return false; }
        };
    }

    private void insert() {
        try (Connection c = DB.get()) {
            FormDialog f = new FormDialog(c, table, null);
            f.setVisible(true);
            if (!f.saved()) return;

            Map<String, Object> v = f.values();
            String sql = "INSERT INTO " + table +
                    " (" + String.join(",", v.keySet()) + ") VALUES (" +
                    String.join(",", Collections.nCopies(v.size(), "?")) + ")";

            try (PreparedStatement ps = c.prepareStatement(sql)) {
                int i = 1;
                for (Object o : v.values()) ps.setObject(i++, o);
                ps.executeUpdate();
            }

            load();
        } catch (Exception e) {
            JOptionPane.showMessageDialog(this, e.getMessage());
        }
    }

    private void update() {
        int r = jtable.getSelectedRow();
        if (r < 0) return;

        Map<String, Object> row = new LinkedHashMap<>();
        for (int c = 0; c < jtable.getColumnCount(); c++) {
            row.put(jtable.getColumnName(c), jtable.getValueAt(r, c));
        }

        try (Connection c = DB.get()) {
            FormDialog f = new FormDialog(c, table, row);
            f.setVisible(true);
            if (!f.saved()) return;

            Map<String, Object> v = f.values();
            StringBuilder set = new StringBuilder();
            StringBuilder where = new StringBuilder();
            java.util.List<Object> p = new ArrayList<>();

            for (String k : v.keySet()) {
                if (!pk.contains(k)) {
                    if (set.length() > 0) set.append(",");
                    set.append(k).append("=?");
                    p.add(v.get(k));
                }
            }

            for (String k : pk) {
                if (where.length() > 0) where.append(" AND ");
                where.append(k).append("=?");
                p.add(v.get(k));
            }

            try (PreparedStatement ps = c.prepareStatement(
                    "UPDATE " + table + " SET " + set + " WHERE " + where)) {
                for (int i = 0; i < p.size(); i++) ps.setObject(i + 1, p.get(i));
                ps.executeUpdate();
            }

            load();
        } catch (Exception e) {
            JOptionPane.showMessageDialog(this, e.getMessage());
        }
    }

    private void delete() {
        int r = jtable.getSelectedRow();
        if (r < 0) return;

        try (Connection c = DB.get()) {
            StringBuilder w = new StringBuilder();
            java.util.List<Object> p = new ArrayList<>();

            for (String k : pk) {
                if (w.length() > 0) w.append(" AND ");
                w.append(k).append("=?");
                p.add(jtable.getValueAt(r, jtable.getColumnModel().getColumnIndex(k)));
            }

            try (PreparedStatement ps = c.prepareStatement(
                    "DELETE FROM " + table + " WHERE " + w)) {
                for (int i = 0; i < p.size(); i++) ps.setObject(i + 1, p.get(i));
                ps.executeUpdate();
            }

            load();
        } catch (Exception e) {
            JOptionPane.showMessageDialog(this, e.getMessage());
        }
    }
}
