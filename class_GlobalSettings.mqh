//+------------------------------------------------------------------+
//| class_GlobalSettings.mqh                                         |
//|                                       Copyright 2026, ShadobaDev |
//|              https://github.com/ShadobaDev/SessionBgIndicatorMT5 |
//| GlobalSettings helper class                                      |
//+------------------------------------------------------------------+
#ifndef __CLASS_GLOBALSETTINGS_MQH__
#define __CLASS_GLOBALSETTINGS_MQH__

//+------------------------------------------------------------------+
//|                                               GlobalSettings.mqh |
//+------------------------------------------------------------------+
#property strict

class GlobalSettings
{
private:
    static GlobalSettings *instance;    // Singleton instance pointer
    string m_prefix;                    // Unique prefix for global variables

    /**
     * \brief Private constructor - prevents creating objects with the 'new' operator outside the class
     */
    GlobalSettings() { m_prefix = "DefaultIndicator"; }

    /**
     * \brief Generate unique key for global variable
     *
     * \param varName Variable name
     * \return Unique key string
     */
    string GetKey(string varName)
    {
        return m_prefix + "_" + varName + "_" + IntegerToString(ChartID());
    }

public:
    /**
     * \brief Destructor
     */
    ~GlobalSettings() 
    { 
        // Clear instance pointer when destroyed
        instance = NULL;
    }

    /**
     * \brief Get singleton instance
     *
     * \return Pointer to GlobalSettings instance
     */
    static GlobalSettings* Get()
    {
        if(instance == NULL) instance = new GlobalSettings();
        return instance;
    }
    
    /**
     * \brief Cleanup singleton instance (deallocate memory)
     * Call this in OnDeinit when indicator is removed or chart closed
     */
    static void Cleanup()
    {
        if(instance != NULL)
        {
            delete instance;
            instance = NULL;
        }
    }

    /**
     * \brief Set unique prefix for global variables
     *
     * \param prefix Prefix string
     */
    void SetPrefix(string prefix) { m_prefix = prefix; }

    /**
     * \brief Initialize integer variable
     *
     * \param name Variable name
     * \param defaultValue Default value
     * \return Initialized value
     */
    int InitInt(string name, int defaultValue)
    {
        string key = GetKey(name);
        if(!GlobalVariableCheck(key))
        {
            GlobalVariableSet(key, (double)defaultValue);
            return defaultValue;
        }
        return (int)GlobalVariableGet(key);
    }

    /**
     * \brief Update integer variable
     *
     * \param name Variable name
     * \param value New value
     */
    void UpdateInt(string name, int value)
    {
        GlobalVariableSet(GetKey(name), (double)value);
    }

    /**
     * \brief Initialize double variable
     *
     * \param name Variable name
     * \param defaultValue Default value
     * \return Initialized value
     */
    double InitDouble(string name, double defaultValue)
    {
        string key = GetKey(name);
        if(!GlobalVariableCheck(key))
        {
            GlobalVariableSet(key, defaultValue);
            return defaultValue;
        }
        return GlobalVariableGet(key);
    }

    /**
     * \brief Update double variable
     *
     * \param name Variable name
     * \param value New value
     */
    void UpdateDouble(string name, double value)
    {
        GlobalVariableSet(GetKey(name), value);
    }

    /**
     * \brief Initialize boolean variable
     *
     * \param name Variable name
     * \param defaultValue Default value
     * \return Initialized value
     */
    bool InitBool(string name, bool defaultValue)
    {
        string key = GetKey(name);
        if(!GlobalVariableCheck(key))
        {
            GlobalVariableSet(key, (double)defaultValue);
            return defaultValue;
        }
        return (bool)GlobalVariableGet(key);
    }

    /**
     * \brief Update boolean variable
     *
     * \param name Variable name
     * \param value New value
     */
    void UpdateBool(string name, bool value)
    {
        GlobalVariableSet(GetKey(name), (double)value);
    }
    
    /**
     * \brief Delete variable
     *
     * \param name Variable name
     */
    void DeleteVar(string name)
    {
        string key = GetKey(name);
        if(GlobalVariableCheck(key))
        {
            GlobalVariableDel(key);
        }
    }
};

static GlobalSettings* GlobalSettings::instance = NULL; //!< Initialize static instance pointer

#endif /* __CLASS_GLOBALSETTINGS_MQH__ */
