//+------------------------------------------------------------------+
//|                                   class_SessionCanvasManager.mqh |
//|                                       Copyright 2026, ShadobaDev |
//|              https://github.com/ShadobaDev/SessionBgIndicatorMT5 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, ShadobaDev"
#property link      "https://github.com/ShadobaDev/SessionBgIndicatorMT5"
#property version   "1.00"
#property strict

#include <Canvas/Canvas.mqh>
#include "class_SessionDay.mqh"

/**
 * \brief Manages a drawing canvas and per-day session rectangles
 *
 * Creates a bitmap canvas attached to the chart and delegates session
 * rectangle calculations to `SessionDay` instances.
 */
class SessionCanvasManager
{
private:
    CCanvas*            m_canvas;       //!< Canvas object for drawing
    SessionDay          m_days[];       //!< Array of session day objects for visible days
    SessionDayParams    m_sharedSessionConfig;  //!< Shared session parameters (colors, times, etc.)
    string              m_name;         //!< Unique name for canvas object (to avoid conflicts with other indicators)
    int                 m_width;        //!< Current chart width in pixels (used for canvas sizing)
    int                 m_height;       //!< Current chart height in pixels (used for canvas sizing)
    
public:

    /**
     * \brief Constructor: initializes canvas and session parameters
     * \param canvasName Unique name for the canvas object (should include chart ID to avoid conflicts)
     */
    SessionCanvasManager(string canvasName) : m_name(canvasName)
    {
        m_canvas = new CCanvas();
        Init();
    }
    
    /**
     * \brief Create or recreate canvas object matching current chart size
     */
    void InitCanvas()
    {
        if(ObjectFind(0, m_name) >= 0) 
            ObjectDelete(0, m_name);
    
        m_width = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
        m_height = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
        
        if(NULL == m_canvas)
        {
            m_canvas = new CCanvas();
        }

        if(!m_canvas.CreateBitmapLabel(m_name, 0, 0, m_width, m_height, COLOR_FORMAT_ARGB_NORMALIZE)) {
            Print("Failed to create canvas object");
        }
        
        m_canvas.FontSizeSet(18);
    }
    
    /**
     * \brief Initialize shared session parameters and precompute days
     * \param nyColor  New York session color
     * \param nyStart  New York session start
     * \param nyEnd    New York session end
     * \param ldColor  London session color
     * \param ldStart  London session start
     * \param ldEnd    London session end
     * \param tkColor  Tokyo session color
     * \param tkStart  Tokyo session start
     * \param tkEnd    Tokyo session end
     */
    void Init(
//--- New York session parameters
        color       nyColor     = clrDodgerBlue,   // NY session color
        SessionTime nyStart     = H15_M00,         // NY start (broker's default time)
        SessionTime nyEnd       = H22_M00,         // NY end

//--- London session parameters 
        color       ldColor     = clrLimeGreen,    // London session color
        SessionTime ldStart     = H08_M00,         // London start (broker's default time)
        SessionTime ldEnd       = H15_M00,         // London end

//--- TOKYO session parameters 
        color       tkColor     = clrOrangeRed,    // TOKYO session color
        SessionTime tkStart     = H01_M00,         // TOKYO start (broker's default time)
        SessionTime tkEnd       = H08_M00         // TOKYO end
        )
    {   
        m_sharedSessionConfig.m_color[TOKYO]    = tkColor;
        m_sharedSessionConfig.m_color[LONDON]   = ldColor;
        m_sharedSessionConfig.m_color[NEWYORK]  = nyColor;
        m_sharedSessionConfig.m_start[TOKYO]    = tkStart;
        m_sharedSessionConfig.m_start[LONDON]   = ldStart;
        m_sharedSessionConfig.m_start[NEWYORK]  = nyStart;
        m_sharedSessionConfig.m_end[TOKYO]      = tkEnd;
        m_sharedSessionConfig.m_end[LONDON]     = ldEnd;
        m_sharedSessionConfig.m_end[NEWYORK]    = nyEnd;
        
        CalculateSesssionDays();

    }
    
    /** \brief Recalculate session rectangles for visible days */
    void CalculateSesssionDays()
    {
        int nDays = NumberOfVisibleDays();
        ArrayFree(m_days);
        ArrayResize(m_days, nDays);
           
        for(int i = 0; i< nDays; i++)
        {
            m_days[i].InsertParams(&m_sharedSessionConfig);
            
            m_days[i].Calculate(i);
        }
    }
    
    /** \brief Erase canvas contents (does not delete canvas object) */
    void DeInit()
    {
        if (NULL != m_canvas)
        {
            m_canvas.Erase();
        }
    }
    
    /** \brief Full reinitialization: erase, recreate canvas and recalc days */
    void ReInit()
    {
        DeInit();
        InitCanvas();
        CalculateSesssionDays();
    }

    /** \brief Destructor: cleans up canvas and session data */
    ~SessionCanvasManager()
    {
        DeInit();
        if (NULL != m_canvas)
        {
            delete m_canvas;
        }
        m_name = NULL;
    }
    
    /** \brief Set how many days to render (from/to) */
    void SetSessionDays(int daysFrom = 0, int daysTo = 0)
    {
        m_sharedSessionConfig.m_daysTo = daysTo;
        m_sharedSessionConfig.m_daysFrom = daysFrom;
    }
    
    /**
     * \brief Compute number of full/partial days visible in the chart viewport
     * \return Number of visible days
     */
    int NumberOfVisibleDays()
    {
        int first_bar_index = (int)ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR);
        datetime time_left = iTime(_Symbol, _Period, first_bar_index);
        
        datetime time_right = iTime(_Symbol, _Period, 0); 

        long seconds_visible = (long)time_right - (long)time_left;
        
        int days_visible = (int)(seconds_visible / 86400);
        
        int partial_day_visible = (int)(seconds_visible % 86400);

        if (partial_day_visible)
        {
            days_visible++;
        }
        
        Print(StringFormat("Visible days: %d", days_visible));
        
        return days_visible;
    }
    
    /** \brief Draw session rectangles for all visible days on the canvas */
    void RenderVisibleDaysOnCanvas() 
    {
        if (_Period == PERIOD_W1 || _Period == PERIOD_MN1 || _Period == PERIOD_D1) return;
        
        m_canvas.Erase(0x00000000); // Transparent background
        for(int i = 0; i < ArraySize(m_days); i++) 
        {
            if(m_days[i].GetVisibilty() == true) 
            {
                switch(m_days[i].GetType())
                {
                    case RenderType::SESSIONS:
                        for(int s = 0; s < 3; s++)
                        {
                            CanvasRectangle *rect = m_days[i].GetRectangle(s);
                            int x1, y1, x2, y2;
                            ChartTimePriceToXY(0, 0, rect._t1, rect._p1, x1, y1);
                            ChartTimePriceToXY(0, 0, rect._t2, rect._p2, x2, y2);
                            
                            uint objColor = ColorToARGB(rect._color, 70); 
                               
                            m_canvas.FillRectangle(x1, y1, x2, y2, objColor);
                            
                            m_canvas.Rectangle(x1, y1, x2, y2, ColorToARGB(rect._color, 180));
                            
                            m_canvas.TextOut(x1,y1-19,"Day("+string(i)+":"+string(s)+")",  ColorToARGB(objColor, 200));
                        }
                        break;
                    case RenderType::DAY:
                        {
                            CanvasRectangle *rect = m_days[i].GetAbsoluteRectangle();    
                            
                            int x1, y1, x2, y2;
                            ChartTimePriceToXY(0, 0, rect._t1, rect._p1, x1, y1);
                            ChartTimePriceToXY(0, 0, rect._t2, rect._p2, x2, y2);
                            
                            uint objColor = ColorToARGB(rect._color, 70); 
                               
                            m_canvas.FillRectangle(x1, y1, x2, y2, objColor);
                            
                            m_canvas.Rectangle(x1, y1, x2, y2, ColorToARGB(rect._color, 180));
                            
                            m_canvas.TextOut(x1,y1-19,"Day("+string(i)+")",  ColorToARGB(objColor, 200));
                            break;
                        }
    
                }
                
            }
        }
        m_canvas.Update();
    }
    
};