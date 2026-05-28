package ui;

import javax.swing.*;
import java.awt.*;

public class MainFrame extends JFrame {
    public MainFrame() {
        setTitle("Travel Agency DBA GUI");
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setSize(1200, 700);
        setLocationRelativeTo(null);

        JTabbedPane tabs = new JTabbedPane();

        tabs.add("Customer", new TablePanel("travel_agency_2025_customer"));
        tabs.add("Trip", new TablePanel("travel_agency_2025_trip"));
        tabs.add("Reservation", new TablePanel("travel_agency_2025_reservation"));
        tabs.add("Destination", new TablePanel("travel_agency_2025_destination"));
        tabs.add("Vehicle", new TablePanel("travel_agency_2025_vehicle"));
        tabs.add("Accommodation", new TablePanel("travel_agency_2025_accommodation"));
        tabs.add("Stay Booking", new TablePanel("travel_agency_2025_stay_booking"));

        add(tabs, BorderLayout.CENTER);
    }
}
