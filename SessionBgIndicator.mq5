//+------------------------------------------------------------------+
//|                                                    SessionBg.mq5 |
//|                                       Copyright 2026, ShadobaDev |
//|              https://github.com/ShadobaDev/SessionBgIndicatorMT5 |
//+------------------------------------------------------------------+

#property copyright "Copyright 2026, ShadobaDev"
#property link      "https://github.com/ShadobaDev/SessionBgIndicatorMT5"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 0
// Mute no inidcator plot defined warning
#property indicator_plots 0

#include "class_SessionCanvasManager.mqh"
#include "class_GlobalSettings.mqh"

//--- Include Controls library headers
#include <Controls\Dialog.mqh>
#include <Controls\Edit.mqh>
#include <Controls\Label.mqh>

//--- Global control objects
CAppDialog   ControlDialog;   // Main container for controls
CLabel       LabelDaysFrom;   // "Days From" label
CLabel       LabelDaysTo;     // "Days To" label
CEdit        EditDaysFrom;    // Edit control for daysFrom
CEdit        EditDaysTo;      // Edit control for daysTo

//--- Zmienne dla pozycji i rozmiarów
input int    GUI_X_Offset = 250;    //!< Distance from right edge for GUI placement
input int    GUI_Y_Start  = 10;     //!< Initial Y position for GUI
input int    GUI_Width    = 280;    //!< Panel width (optional) - adjust as needed for content

//--- Enable debug logging (prints chart events to log)
#define DEBUG 0

//--- New York session parameters
//input color       NY_Color   = clrMidnightBlue; // For a drak mode
input color       NY_Color     = clrDodgerBlue;   // NY session color
input SessionTime NY_Start     = H15_M00;         // NY start (broker's default time)
input SessionTime NY_End       = H22_M00;         // NY end

//--- London session parameters 
//input color       LD_Color     = clrDarkSlateGray; // For a drak mode
input color       LD_Color     = clrLimeGreen;    // London session color
input SessionTime LD_Start     = H08_M00;         // London start (broker's default time)
input SessionTime LD_End       = H15_M00;         // London end

//--- Tokyo session parameters 
//input color       TK_Color     = clrMaroon;    // For a dark mode
input color       TK_Color     = clrOrangeRed;    // Tokyo session color
input SessionTime TK_Start     = H01_M00;         // Tokyo start (broker's default time)
input SessionTime TK_End       = H08_M00;         // Tokyo end

//--- Auxiliary parametrs
// input bool        ShowBorders  = true;            // Show borders
// input bool        ShowLabels   = true;            // Show labels
// input double      LabelOffset  = 0.999;            // Labels may apear in a palce taht is hardly visible, this paramter can move it up and down


SessionCanvasManager *g_SCM;

/**
 * \brief Generate a unique object name using chart ID and a base name
 *
 * This ensures that objects created by this indicator do not conflict with other indicators or instances.
 * \param baseName Base name for the object (e.g., "SessionBg", "SessionControls")
 * \return Unique object name string
 */
string UniqueObjectName(const string baseName)
{
    return(StringFormat("SBI_%d_%s", ChartID(), baseName));
}

/**
 * \brief Remove GUI objects created by this indicator and leftovers from older versions
 *
 * This removes a small set of known object names and any object prefixed with "SBI_".
 */
void DeleteAllSBIObjects()
{
    string oldNames[6] = {"SessionControls", "LblFrom", "EditFrom", "LblTo", "EditTo", "SessionBg"};
    for(int j = 0; j < ArraySize(oldNames); j++)
    {
        if(ObjectFind(0, oldNames[j]) >= 0)
            ObjectDelete(0, oldNames[j]);
    }

    int total = ObjectsTotal(0);
    for(int i = total - 1; i >= 0; i--)
    {
        string name = ObjectName(0, i);
        if(StringFind(name, "SBI_") == 0)
            ObjectDelete(0, name);
    }
}

//+------------------------------------------------------------------+
//| Deinit                                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if(NULL != g_SCM)
        delete g_SCM;
    
    if(reason == REASON_REMOVE || reason == REASON_CHARTCLOSE)
    {
        GlobalSettings::Get().DeleteVar("From");
        GlobalSettings::Get().DeleteVar("To");
    }

    GlobalSettings::Cleanup();  // Deallocate singleton
    ControlDialog.Destroy(reason);
    LabelDaysFrom.Destroy(reason);
    LabelDaysTo.Destroy(reason);
    EditDaysFrom.Destroy(reason);
    EditDaysTo.Destroy(reason);

    // Remove GUI objects only on permanent removal/close/recompile.
    // On chart change (REASON_CHARTCHANGE) the indicator re-initializes, so we avoid
    // deleting objects here to prevent brief disappearance in debug/tester modes.
    if(reason == REASON_REMOVE || reason == REASON_CHARTCLOSE || reason == REASON_RECOMPILE)
    {
        DeleteAllSBIObjects();
    }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    string canvasName   = UniqueObjectName("SessionBg");
    string dialogName   = UniqueObjectName("SessionControls");
    string labelFromName= UniqueObjectName("LblFrom");
    string editFromName = UniqueObjectName("EditFrom");
    string labelToName  = UniqueObjectName("LblTo");
    string editToName   = UniqueObjectName("EditTo");

    // Remove leftover objects that may remain from a template or previous initialization
    DeleteAllSBIObjects();

    g_SCM = new SessionCanvasManager(canvasName);
    g_SCM.InitCanvas();
    g_SCM.Init(
            NY_Color
        ,   NY_Start
        ,   NY_End
        ,   LD_Color
        ,   LD_Start
        ,   LD_End
        ,   TK_Color
        ,   TK_Start
        ,   TK_End
    );

    GlobalSettings::Get().SetPrefix("SBI");
    int DaysFrom = GlobalSettings::Get().InitInt("From", 0);
    int DaysTo = GlobalSettings::Get().InitInt("To", 0);

    int chartWidth = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
    if(chartWidth <= 0)
        chartWidth = GUI_Width + GUI_X_Offset + 50;

    int dialogLeft  = chartWidth - GUI_Width - GUI_X_Offset;
    if(dialogLeft < 0)
        dialogLeft = 0;
    int dialogRight = dialogLeft + GUI_Width;

        if(!ControlDialog.Create(0, dialogName, 0,
                                                        dialogLeft,
                                                        GUI_Y_Start,
                                                        dialogRight,
                                                        GUI_Y_Start + 100))
        {
            Print("Failed to create ControlDialog: ", GetLastError());
            return(INIT_FAILED);
        }
        ControlDialog.Caption("Session days"); // Hide the standard title bar
    //ControlDialog.CloseButton(true);
     
    //--- Create label and field for Days From
    int xPos = 10;
    int yPos = 10;
    int xSize = 120;
    int ySize = 20;
    
        if(!LabelDaysFrom.Create(0, labelFromName, 0, xPos, yPos, xSize, ySize))
        {
            Print("Failed to create LabelDaysFrom: ", GetLastError());
            return(INIT_FAILED);
        }
        LabelDaysFrom.Text("Days From:");
        ControlDialog.Add(LabelDaysFrom);
    
    xPos = xSize;
    yPos = 10;
    xSize = xSize+100;
    ySize = 40;
    
        if(!EditDaysFrom.Create(0, editFromName, 0, xPos, yPos, xSize, ySize))
        {
            Print("Failed to create EditDaysFrom: ", GetLastError());
            return(INIT_FAILED);
        }
        EditDaysFrom.Text(IntegerToString(DaysFrom)); // Default value
        ControlDialog.Add(EditDaysFrom);
        EditDaysFrom.ReadOnly(false); // Ensure the field is editable

    //--- Create label and field for Days To (below)
    xPos = 10;
    yPos = 40;
    xSize = 120;
    ySize = 50;
     
        if(!LabelDaysTo.Create(0, labelToName, 0, xPos, yPos, xSize, ySize))
        {
            Print("Failed to create LabelDaysTo: ", GetLastError());
            return(INIT_FAILED);
        }
        LabelDaysTo.Text("Days To:");
        ControlDialog.Add(LabelDaysTo);
    
    xPos = xSize;
    yPos = 40;
    xSize = xSize+100;
    ySize = 70;
    
        if(!EditDaysTo.Create(0, editToName, 0, xPos, yPos, xSize, ySize))
        {
            Print("Failed to create EditDaysTo: ", GetLastError());
            return(INIT_FAILED);
        }
        EditDaysTo.Text(IntegerToString(DaysTo)); // Default value
        ControlDialog.Add(EditDaysTo);
        EditDaysTo.ReadOnly(false); // Ensure the field is editable
    
    ObjectSetInteger(0, ControlDialog.Name(), OBJPROP_ZORDER, 1000);
    ObjectSetInteger(0, EditDaysFrom.Name(), OBJPROP_ZORDER, 1001);
    ObjectSetInteger(0, EditDaysTo.Name(), OBJPROP_ZORDER, 1001);

    ControlDialog.Run();
    ControlDialog.Show();
    ControlDialog.BringToTop();
    ControlDialog.Enable();
    ChartRedraw();
   
    return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
//---
/*
    static int last_id = 0;
    if(id != last_id) // Wypisuj tylko przy zmianie typu zdarzenia, aby nie zaśmiecać logu
    {
        Print("Debug OnChartEvent -> id: ", id, ", sparam: ", sparam);
        last_id = id;
    } */

    ControlDialog.ChartEvent(id,lparam,dparam,sparam);
    switch(id)
    {
    case CHARTEVENT_OBJECT_ENDEDIT:
        if(sparam == EditDaysFrom.Name() || sparam == EditDaysTo.Name())
        {
            
            // Convert to integers and update indicator logic
            int daysFrom = (int)StringToInteger(EditDaysFrom.Text());
            int daysTo = (int)StringToInteger(EditDaysTo.Text());
            GlobalSettings::Get().UpdateInt("From", daysFrom);
            GlobalSettings::Get().UpdateInt("To", daysTo);
    
            g_SCM.SetSessionDays(daysFrom, daysTo);
        }
        // Intentional fallthrough
    case CHARTEVENT_CHART_CHANGE:
        {
            g_SCM.ReInit();
            int daysFrom = GlobalSettings::Get().InitInt("From", 0);
            int daysTo = GlobalSettings::Get().InitInt("To", 0);
            EditDaysFrom.Text(IntegerToString(daysFrom));
            EditDaysTo.Text(IntegerToString(daysTo));
            g_SCM.SetSessionDays(daysFrom, daysTo);
            g_SCM.RenderVisibleDaysOnCanvas();
            break;
        }
    }
    ChartRedraw();
    
}
//+------------------------------------------------------------------+


