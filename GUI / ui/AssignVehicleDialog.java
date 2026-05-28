package ui;

import app.DB;
import javax.swing.*;
import java.sql.*;

public class AssignVehicleDialog extends JDialog {
    public AssignVehicleDialog(int trId) throws Exception {
        setModal(true);
        setSize(400,200);

        JComboBox<String> cb=new JComboBox<>();
        try(Connection c=DB.get()){
            PreparedStatement ps=c.prepareStatement(
              "SELECT veh_id,veh_plate FROM travel_agency_2025_vehicle " +
              "WHERE veh_status='AVAILABLE'");
            ResultSet rs=ps.executeQuery();
            while(rs.next())
                cb.addItem(rs.getInt(1)+" - "+rs.getString(2));
        }

        JButton b=new JButton("Assign");
        b.addActionListener(e->{
            try(Connection c=DB.get()){
                String s=cb.getSelectedItem().toString();
                int veh=Integer.parseInt(s.split(" ")[0]);
                CallableStatement cs=c.prepareCall("CALL sp_assign_vehicle_to_trip(?,?,?)");
                cs.setInt(1,trId);
                cs.setInt(2,veh);
                cs.setInt(3,0);
                cs.execute();
                setVisible(false);
            }catch(Exception ex){
                JOptionPane.showMessageDialog(this,ex.getMessage());
            }
        });

        add(cb);
        add(b, "South");
    }
}
