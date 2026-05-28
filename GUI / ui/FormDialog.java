package ui;

import javax.swing.*;
import java.awt.*;
import java.sql.*;
import java.util.*;

public class FormDialog extends JDialog {
    private boolean saved = false;
    private final Map<String, JComponent> fields = new LinkedHashMap<>();

    public FormDialog(Connection c, String table, Map<String, Object> preset) throws SQLException {
        setModal(true);
        setSize(520, 520);
        setLocationRelativeTo(null);

        JPanel p = new JPanel(new GridLayout(0, 2, 6, 6));

        PreparedStatement ps = c.prepareStatement(
            "SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, EXTRA " +
            "FROM INFORMATION_SCHEMA.COLUMNS " +
            "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? " +
            "ORDER BY ORDINAL_POSITION"
        );
        ps.setString(1, table);
        ResultSet rs = ps.executeQuery();

        while (rs.next()) {
            String name = rs.getString(1);
            String type = rs.getString(2);
            String isNullable = rs.getString(3);
            String extra = rs.getString(4);

            p.add(new JLabel(name));

            JComponent comp;
            if (type != null && type.startsWith("enum(")) {
                String[] v = type.substring(5, type.length() - 1).replace("'", "").split(",");
                comp = new JComboBox<>(v);
            } else {
                comp = new JTextField();
            }

            Object val = (preset == null) ? null : preset.get(name);
            if (val != null) {
                if (comp instanceof JComboBox<?> cb) cb.setSelectedItem(val.toString());
                else ((JTextField) comp).setText(val.toString());
            }

            if (preset == null && extra != null && extra.toLowerCase().contains("auto_increment")) {
                if (comp instanceof JTextField tf) tf.setText("");
            }

            fields.put(name, comp);
            p.add(comp);
        }

        JButton ok = new JButton("Save");
        JButton cancel = new JButton("Cancel");

        ok.addActionListener(e -> { saved = true; setVisible(false); });
        cancel.addActionListener(e -> setVisible(false));

        JPanel bottom = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        bottom.add(cancel);
        bottom.add(ok);

        add(new JScrollPane(p), BorderLayout.CENTER);
        add(bottom, BorderLayout.SOUTH);
    }

    public boolean saved() { return saved; }

    public Map<String, Object> values() {
        Map<String, Object> m = new LinkedHashMap<>();
        for (var e : fields.entrySet()) {
            Object v = (e.getValue() instanceof JComboBox<?> cb)
                ? cb.getSelectedItem()
                : ((JTextField) e.getValue()).getText();

            if (v != null && v.toString().isBlank()) v = null;
            m.put(e.getKey(), v);
        }
        return m;
    }
}

