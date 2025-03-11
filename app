import React, { useState, useEffect, useRef } from 'react';
import { Check, Clock, ListTodo, Plus, Filter, User, Upload, AlertCircle, X, ChevronDown, ChevronRight, Edit, Save } from 'lucide-react';
import Papa from 'papaparse';

const SemiconTaskTracker = () => {
  // 定義任務狀態
  const STATUS_TYPES = {
    TODO: '待辦',
    IN_PROGRESS: '進行中',
    COMPLETED: '已完成'
  };

  // 初始化任務狀態
  const [tasks, setTasks] = useState([]);
  const [filteredTasks, setFilteredTasks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('all');
  const [assigneeFilter, setAssigneeFilter] = useState('all');
  const [assignees, setAssignees] = useState([]);
  const [showImport, setShowImport] = useState(false);
  const [importError, setImportError] = useState('');
  const [importSuccess, setImportSuccess] = useState(false);
  const [expandedTasks, setExpandedTasks] = useState({});
  
  // 新子任務表單
  const [newSubtask, setNewSubtask] = useState({
    name: '',
    assignee: '',
    status: STATUS_TYPES.TODO
  });
  
  // 編輯子任務
  const [editingSubtask, setEditingSubtask] = useState(null);
  
  // 引用DOM元素
  const fileInputRef = useRef(null);
  
  // 初始化示例任務數據
  useEffect(() => {
    const loadInitialTasks = () => {
      setLoading(true);
      
      // 增強版本支持子任務負責人的數據
      const initialTasks = [
        { 
          id: '1.1', 
          name: '展覽預算表', 
          category: '展場規劃與設計', 
          assignee: 'Wilson Chen', 
          status: STATUS_TYPES.IN_PROGRESS,
          subtasks: []
        },
        { 
          id: '1.2', 
          name: '展覽3D視圖', 
          category: '展場規劃與設計', 
          assignee: 'Wilson Chen', 
          status: STATUS_TYPES.IN_PROGRESS,
          subtasks: [
            { id: '1.2.1', name: '外包設計', assignee: '一如設計公司', status: STATUS_TYPES.IN_PROGRESS }
          ]
        },
        { 
          id: '1.3', 
          name: '裝潢 x PICO', 
          category: '展場規劃與設計', 
          assignee: 'Wilson Chen', 
          status: STATUS_TYPES.IN_PROGRESS,
          subtasks: [
            { id: '1.3.1', name: '確認需求', assignee: 'Wilson Chen', status: STATUS_TYPES.COMPLETED },
            { id: '1.3.2', name: '報價', assignee: 'PICO', status: STATUS_TYPES.COMPLETED },
            { id: '1.3.3', name: '下單', assignee: 'Wilson Chen', status: STATUS_TYPES.IN_PROGRESS },
            { id: '1.3.4', name: '螢幕租借', assignee: 'PICO', status: STATUS_TYPES.TODO }
          ]
        },
        { 
          id: '2.1', 
          name: '資訊更新', 
          category: 'SEMI 後台', 
          assignee: 'Wilson Chen & Tiffany Feng', 
          status: STATUS_TYPES.TODO,
          subtasks: []
        },
        { 
          id: '2.2', 
          name: '填寫展場表單', 
          category: 'SEMI 後台', 
          assignee: 'Tiffany Feng', 
          status: STATUS_TYPES.TODO,
          subtasks: []
        },
        { 
          id: '3.1', 
          name: '展場贈品', 
          category: '現場服務與體驗', 
          assignee: 'Claire Hsu', 
          status: STATUS_TYPES.IN_PROGRESS,
          subtasks: [
            { id: '3.1.1', name: '尋找廠商', assignee: 'Jay Hsu', status: STATUS_TYPES.COMPLETED },
            { id: '3.1.2', name: '確認價格', assignee: 'Claire Hsu', status: STATUS_TYPES.IN_PROGRESS },
            { id: '3.1.3', name: '下單', assignee: 'Claire Hsu', status: STATUS_TYPES.TODO },
            { id: '3.1.4', name: '送達驗貨', assignee: 'Claire Hsu', status: STATUS_TYPES.TODO }
          ]
        }
      ];
      
      // 提取所有唯一的負責人（包括子任務的負責人）
      const allAssignees = [];
      initialTasks.forEach(task => {
        if (task.assignee) {
          const assigneeList = task.assignee.split('&').map(a => a.trim());
          allAssignees.push(...assigneeList);
        }
        
        if (task.subtasks) {
          task.subtasks.forEach(subtask => {
            if (typeof subtask === 'object' && subtask.assignee) {
              allAssignees.push(subtask.assignee);
            }
          });
        }
      });
      
      const uniqueAssignees = [...new Set(allAssignees)].filter(Boolean);
      
      setTasks(initialTasks);
      setFilteredTasks(initialTasks);
      setAssignees(uniqueAssignees);
      setLoading(false);
    };
    
    loadInitialTasks();
  }, []);

  // 應用過濾器
  useEffect(() => {
    let result = [...tasks];
    
    // 狀態過濾
    if (statusFilter !== 'all') {
      result = result.filter(task => task.status === statusFilter);
    }
    
    // 負責人過濾（包括子任務的負責人）
    if (assigneeFilter !== 'all') {
      result = result.filter(task => {
        // 檢查主任務負責人
        if (task.assignee && task.assignee.includes(assigneeFilter)) {
          return true;
        }
        
        // 檢查子任務負責人
        if (task.subtasks && task.subtasks.length > 0) {
          return task.subtasks.some(subtask => {
            if (typeof subtask === 'object' && subtask.assignee) {
              return subtask.assignee.includes(assigneeFilter);
            }
            return false;
          });
        }
        
        return false;
      });
    }
    
    setFilteredTasks(result);
  }, [statusFilter, assigneeFilter, tasks]);

  // 處理任務狀態變更
  const handleStatusChange = (id, newStatus) => {
    const updatedTasks = tasks.map(task => {
      if (task.id === id) {
        return { ...task, status: newStatus };
      }
      return task;
    });
    
    setTasks(updatedTasks);
  };

  // 處理子任務狀態變更
  const handleSubtaskStatusChange = (taskId, subtaskId, newStatus) => {
    const updatedTasks = tasks.map(task => {
      if (task.id === taskId) {
        const updatedSubtasks = task.subtasks.map(subtask => {
          if (subtask.id === subtaskId) {
            return { ...subtask, status: newStatus };
          }
          return subtask;
        });
        return { ...task, subtasks: updatedSubtasks };
      }
      return task;
    });
    
    setTasks(updatedTasks);
  };

  // 獲取狀態圖標
  const getStatusIcon = (status) => {
    switch(status) {
      case STATUS_TYPES.TODO:
        return <ListTodo className="text-gray-500" size={18} />;
      case STATUS_TYPES.IN_PROGRESS:
        return <Clock className="text-blue-500" size={18} />;
      case STATUS_TYPES.COMPLETED:
        return <Check className="text-green-500" size={18} />;
      default:
        return <ListTodo className="text-gray-500" size={18} />;
    }
  };

  // 計算狀態統計
  const getStatusCounts = () => {
    const counts = {
      total: tasks.length,
      [STATUS_TYPES.TODO]: tasks.filter(task => task.status === STATUS_TYPES.TODO).length,
      [STATUS_TYPES.IN_PROGRESS]: tasks.filter(task => task.status === STATUS_TYPES.IN_PROGRESS).length,
      [STATUS_TYPES.COMPLETED]: tasks.filter(task => task.status === STATUS_TYPES.COMPLETED).length
    };
    return counts;
  };

  // 切換任務展開/收起
  const toggleTaskExpand = (taskId) => {
    setExpandedTasks(prev => ({
      ...prev,
      [taskId]: !prev[taskId]
    }));
  };

  // 添加子任務
  const handleAddSubtask = (taskId) => {
    if (!newSubtask.name || !newSubtask.assignee) {
      alert('請填寫子任務名稱和負責人');
      return;
    }

    const updatedTasks = tasks.map(task => {
      if (task.id === taskId) {
        // 生成子任務ID
        const subtaskId = `${taskId}.${task.subtasks.length + 1}`;
        
        const newSubtaskItem = {
          id: subtaskId,
          name: newSubtask.name,
          assignee: newSubtask.assignee,
          status: newSubtask.status
        };
        
        return {
          ...task,
          subtasks: [...task.subtasks, newSubtaskItem]
        };
      }
      return task;
    });
    
    setTasks(updatedTasks);
    
    // 更新負責人列表
    if (!assignees.includes(newSubtask.assignee)) {
      setAssignees([...assignees, newSubtask.assignee]);
    }
    
    // 重置表單
    setNewSubtask({
      name: '',
      assignee: '',
      status: STATUS_TYPES.TODO
    });
  };

  // 開始編輯子任務
  const startEditSubtask = (taskId, subtask) => {
    setEditingSubtask({
      taskId,
      subtaskId: subtask.id
    });
    
    // 設置編輯表單的初始值
    setNewSubtask({
      name: subtask.name,
      assignee: subtask.assignee,
      status: subtask.status
    });
  };

  // 保存子任務編輯
  const saveSubtaskEdit = () => {
    if (!newSubtask.name || !newSubtask.assignee) {
      alert('請填寫子任務名稱和負責人');
      return;
    }

    const updatedTasks = tasks.map(task => {
      if (task.id === editingSubtask.taskId) {
        const updatedSubtasks = task.subtasks.map(subtask => {
          if (subtask.id === editingSubtask.subtaskId) {
            return {
              ...subtask,
              name: newSubtask.name,
              assignee: newSubtask.assignee,
              status: newSubtask.status
            };
          }
          return subtask;
        });
        return { ...task, subtasks: updatedSubtasks };
      }
      return task;
    });
    
    setTasks(updatedTasks);
    
    // 更新負責人列表
    if (!assignees.includes(newSubtask.assignee)) {
      setAssignees([...assignees, newSubtask.assignee]);
    }
    
    // 重置表單和編輯狀態
    setNewSubtask({
      name: '',
      assignee: '',
      status: STATUS_TYPES.TODO
    });
    setEditingSubtask(null);
  };

  // 取消編輯
  const cancelEditSubtask = () => {
    setEditingSubtask(null);
    setNewSubtask({
      name: '',
      assignee: '',
      status: STATUS_TYPES.TODO
    });
  };

  // 處理文件導入
  const handleFileImport = (event) => {
    const file = event.target.files[0];
    if (!file) return;
    
    setImportError('');
    setImportSuccess(false);
    
    const fileExt = file.name.split('.').pop().toLowerCase();
    
    // 處理CSV文件
    if (fileExt === 'csv') {
      Papa.parse(file, {
        header: true,
        skipEmptyLines: true,
        complete: (results) => {
          if (results.errors.length > 0) {
            setImportError(`解析CSV時發生錯誤: ${results.errors[0].message}`);
            return;
          }
          
          try {
            // 區分主任務和子任務
            const mainTasks = [];
            const subtasksMap = {};
            
            results.data.forEach((row, index) => {
              // 檢查是否為子任務（通過parent_id欄位）
              if (row.parent_id) {
                if (!subtasksMap[row.parent_id]) {
                  subtasksMap[row.parent_id] = [];
                }
                
                subtasksMap[row.parent_id].push({
                  id: row.id || `subtask-${index}`,
                  name: row.name || `子任務 ${index}`,
                  assignee: row.assignee || '',
                  status: row.status || STATUS_TYPES.TODO
                });
              } else {
                // 主任務
                mainTasks.push({
                  id: row.id || `task-${index}`,
                  name: row.name || `任務 ${index}`,
                  category: row.category || '未分類',
                  assignee: row.assignee || '',
                  status: row.status || STATUS_TYPES.TODO,
                  subtasks: []
                });
              }
            });
            
            // 將子任務添加到相應的主任務
            mainTasks.forEach(task => {
              if (subtasksMap[task.id]) {
                task.subtasks = subtasksMap[task.id];
              }
            });
            
            // 提取所有負責人
            const allAssignees = [];
            
            // 從主任務提取
            mainTasks.forEach(task => {
              if (task.assignee) {
                allAssignees.push(task.assignee);
              }
              
              // 從子任務提取
              if (task.subtasks) {
                task.subtasks.forEach(subtask => {
                  if (subtask.assignee) {
                    allAssignees.push(subtask.assignee);
                  }
                });
              }
            });
            
            // 更新任務和負責人列表
            const uniqueAssignees = [...new Set([
              ...assignees,
              ...allAssignees
            ])].filter(Boolean);
            
            setTasks([...mainTasks, ...tasks]);
            setAssignees(uniqueAssignees);
            setImportSuccess(true);
            
            // 清除文件輸入
            if (fileInputRef.current) {
              fileInputRef.current.value = '';
            }
          } catch (error) {
            setImportError(`處理導入數據時發生錯誤: ${error.message}`);
          }
        },
        error: (error) => {
          setImportError(`讀取CSV文件時發生錯誤: ${error.message}`);
        }
      });
    }
    // 處理JSON文件
    else if (fileExt === 'json') {
      const reader = new FileReader();
      reader.onload = (e) => {
        try {
          const importedData = JSON.parse(e.target.result);
          
          // 驗證數據格式
          if (!Array.isArray(importedData)) {
            setImportError('JSON文件必須包含任務數組');
            return;
          }
          
          const importedTasks = importedData.map((item, index) => {
            // 處理子任務
            let subtasks = [];
            if (Array.isArray(item.subtasks)) {
              subtasks = item.subtasks.map((subtask, subIndex) => {
                if (typeof subtask === 'string') {
                  // 將字符串子任務轉換為對象形式
                  return {
                    id: `${item.id || `task-${index}`}.${subIndex + 1}`,
                    name: subtask,
                    assignee: '',
                    status: STATUS_TYPES.TODO
                  };
                } else if (typeof subtask === 'object') {
                  // 對象形式的子任務
                  return {
                    id: subtask.id || `${item.id || `task-${index}`}.${subIndex + 1}`,
                    name: subtask.name || `子任務 ${subIndex + 1}`,
                    assignee: subtask.assignee || '',
                    status: subtask.status || STATUS_TYPES.TODO
                  };
                }
                return null;
              }).filter(Boolean);
            }
            
            return {
              id: item.id || `task-${index}`,
              name: item.name || `任務 ${index}`,
              category: item.category || '未分類',
              assignee: item.assignee || '',
              status: item.status || STATUS_TYPES.TODO,
              subtasks: subtasks
            };
          });
          
          // 提取所有負責人
          const allAssignees = [];
          
          importedTasks.forEach(task => {
            if (task.assignee) {
              allAssignees.push(task.assignee);
            }
            
            if (task.subtasks) {
              task.subtasks.forEach(subtask => {
                if (subtask.assignee) {
                  allAssignees.push(subtask.assignee);
                }
              });
            }
          });
          
          // 更新任務和負責人列表
          const uniqueAssignees = [...new Set([
            ...assignees,
            ...allAssignees
          ])].filter(Boolean);
          
          setTasks([...importedTasks, ...tasks]);
          setAssignees(uniqueAssignees);
          setImportSuccess(true);
          
          // 清除文件輸入
          if (fileInputRef.current) {
            fileInputRef.current.value = '';
          }
        } catch (error) {
          setImportError(`解析JSON文件時發生錯誤: ${error.message}`);
        }
      };
      reader.onerror = () => {
        setImportError('讀取文件時發生錯誤');
      };
      reader.readAsText(file);
    }
    // 不支持的文件類型
    else {
      setImportError('不支持的文件類型，請使用 CSV 或 JSON 文件');
    }
  };

  // 導出任務列表為CSV
  const exportToCSV = () => {
    // 準備CSV數據（主任務和子任務分開）
    const csvData = [];
    
    // 添加主任務
    tasks.forEach(task => {
      csvData.push({
        parent_id: '',
        id: task.id,
        name: task.name,
        category: task.category,
        assignee: task.assignee,
        status: task.status
      });
      
      // 添加子任務
      if (task.subtasks && task.subtasks.length > 0) {
        task.subtasks.forEach(subtask => {
          if (typeof subtask === 'object') {
            csvData.push({
              parent_id: task.id,
              id: subtask.id,
              name: subtask.name,
              category: '',
              assignee: subtask.assignee,
              status: subtask.status
            });
          } else if (typeof subtask === 'string') {
            csvData.push({
              parent_id: task.id,
              id: '',
              name: subtask,
              category: '',
              assignee: '',
              status: ''
            });
          }
        });
      }
    });
    
    // 使用Papa Parse將JSON轉為CSV字符串
    const csv = Papa.unparse(csvData);
    
    // 創建Blob對象
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    
    // 創建下載鏈接
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', 'semicon_tasks.csv');
    link.style.visibility = 'hidden';
    
    // 添加鏈接到文檔並觸發點擊
    document.body.appendChild(link);
    link.click();
    
    // 清理
    document.body.removeChild(link);
  };

  const statusCounts = getStatusCounts();

  // 如果正在加載，顯示加載指示器
  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto"></div>
          <p className="mt-4 text-gray-600">載入中...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="w-full mx-auto bg-white rounded-lg shadow">
      {/* 頁頭 */}
      <div className="p-6 border-b">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-bold text-gray-800">Semicon SEA 2025 任務追蹤</h1>
          <div className="flex space-x-2">
            <button
              onClick={() => setShowImport(true)}
              className="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded-md flex items-center"
            >
              <Upload size={18} className="mr-1" /> 導入任務
            </button>
            <button
              onClick={exportToCSV}
              className="bg-green-500 hover:bg-green-600 text-white px-4 py-2 rounded-md flex items-center"
            >
              <Upload size={18} className="mr-1 transform rotate-180" /> 導出CSV
            </button>
          </div>
        </div>
        
        {/* 狀態卡片 */}
        <div className="grid grid-cols-4 gap-4 mt-6">
          <div className="bg-gray-100 p-4 rounded-lg">
            <div className="flex justify-between items-center">
              <h2 className="text-lg font-medium text-gray-700">總任務數</h2>
              <span className="text-2xl font-bold text-gray-800">{statusCounts.total}</span>
            </div>
          </div>
          <div className="bg-yellow-50 p-4 rounded-lg">
            <div className="flex justify-between items-center">
              <h2 className="text-lg font-medium text-yellow-700">待辦</h2>
              <span className="text-2xl font-bold text-yellow-600">{statusCounts[STATUS_TYPES.TODO]}</span>
            </div>
          </div>
          <div className="bg-blue-50 p-4 rounded-lg">
            <div className="flex justify-between items-center">
              <h2 className="text-lg font-medium text-blue-700">進行中</h2>
              <span className="text-2xl font-bold text-blue-600">{statusCounts[STATUS_TYPES.IN_PROGRESS]}</span>
            </div>
          </div>
          <div className="bg-green-50 p-4 rounded-lg">
            <div className="flex justify-between items-center">
              <h2 className="text-lg font-medium text-green-700">已完成</h2>
              <span className="text-2xl font-bold text-green-600">{statusCounts[STATUS_TYPES.COMPLETED]}</span>
            </div>
          </div>
        </div>
      </div>
      
      {/* 過濾器 */}
      <div className="p-4 border-b bg-gray-50">
        <div className="flex items-center space-x-4">
          <div className="flex items-center">
            <Filter size={18} className="text-gray-500 mr-2" />
            <span className="text-gray-600 mr-2">狀態:</span>
            <select 
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="border rounded-md px-3 py-1.5"
            >
              <option value="all">全部</option>
              <option value={STATUS_TYPES.TODO}>待辦</option>
              <option value={STATUS_TYPES.IN_PROGRESS}>進行中</option>
              <option value={STATUS_TYPES.COMPLETED}>已完成</option>
            </select>
          </div>
          
          <div className="flex items-center">
            <User size={18} className="text-gray-500 mr-2" />
            <span className="text-gray-600 mr-2">負責人:</span>
            <select 
              value={assigneeFilter}
              onChange={(e) => setAssigneeFilter(e.target.value)}
              className="border rounded-md px-3 py-1.5"
            >
              <option value="all">全部</option>
              {assignees.map((assignee, index) => (
                <option key={index} value={assignee}>{assignee}</option>
              ))}
            </select>
          </div>
        </div>
      </div>
      
      {/* 任務列表 */}
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">狀態</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">任務</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">分類</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">負責人</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">子任務</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">操作</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {filteredTasks.length === 0 ? (
              <tr>
                <td colSpan="7" className="px-6 py-12 text-center text-gray-500">
                  沒有符合條件的任務
                </td>
              </tr>
            ) : (
              filteredTasks.map((task) => (
                <React.Fragment key={task.id}>
                  {/* 主任務行 */}
                  <tr className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {task.id}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        {getStatusIcon(task.status)}
                        <span className="ml-2 text-sm text-gray-700">
                          {task.status}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm font-medium text-gray-900">{task.name}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="text-sm text-gray-700">
                        {task.category}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="px-2 py-1 text-sm bg-blue-100 text-blue-800 rounded-full">
                        {task.assignee}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <button
                        onClick={() => toggleTaskExpand(task.id)}
                        className="flex items-center text-blue-600 hover:text-blue-800"
                      >
                        {task.subtasks && task.subtasks.length > 0 ? (
                          <>
                            {expandedTasks[task.id] ? (
                              <ChevronDown size={18} className="mr-1" />
                            ) : (<ChevronRight size={18} className="mr-1" />
                            )}
                            <span className="text-sm">{task.subtasks.length} 個子任務</span>
                          </>
                        ) : (
                          <span className="text-sm text-gray-500">無子任務</span>
                        )}
                      </button>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm">
                      <div className="flex items-center space-x-2">
                        {task.status !== STATUS_TYPES.TODO && (
                          <button 
                            onClick={() => handleStatusChange(task.id, STATUS_TYPES.TODO)}
                            className="text-yellow-600 hover:text-yellow-800"
                            title="設為待辦"
                          >
                            <ListTodo size={18} />
                          </button>
                        )}
                        {task.status !== STATUS_TYPES.IN_PROGRESS && (
                          <button 
                            onClick={() => handleStatusChange(task.id, STATUS_TYPES.IN_PROGRESS)}
                            className="text-blue-600 hover:text-blue-800"
                            title="設為進行中"
                          >
                            <Clock size={18} />
                          </button>
                        )}
                        {task.status !== STATUS_TYPES.COMPLETED && (
                          <button 
                            onClick={() => handleStatusChange(task.id, STATUS_TYPES.COMPLETED)}
                            className="text-green-600 hover:text-green-800"
                            title="設為已完成"
                          >
                            <Check size={18} />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                  
                  {/* 子任務展開面板 */}
                  {expandedTasks[task.id] && (
                    <tr>
                      <td colSpan="7" className="p-0 border-t-0">
                        <div className="bg-gray-50 px-6 py-4">
                          <h3 className="text-lg font-medium text-gray-700 mb-4">{task.name} 的子任務</h3>
                          
                          {/* 子任務列表 */}
                          <div className="bg-white rounded-md shadow overflow-hidden mb-4">
                            <table className="min-w-full divide-y divide-gray-200">
                              <thead className="bg-gray-100">
                                <tr>
                                  <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                                  <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">子任務</th>
                                  <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">負責人</th>
                                  <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">狀態</th>
                                  <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">操作</th>
                                </tr>
                              </thead>
                              <tbody className="bg-white divide-y divide-gray-200">
                                {task.subtasks.map((subtask) => (
                                  <tr key={subtask.id} className="hover:bg-gray-50">
                                    <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-500">
                                      {subtask.id}
                                    </td>
                                    <td className="px-4 py-3 text-sm">
                                      {editingSubtask && 
                                       editingSubtask.taskId === task.id && 
                                       editingSubtask.subtaskId === subtask.id ? (
                                        <input
                                          type="text"
                                          value={newSubtask.name}
                                          onChange={(e) => setNewSubtask({...newSubtask, name: e.target.value})}
                                          className="w-full border rounded px-2 py-1"
                                        />
                                      ) : (
                                        subtask.name
                                      )}
                                    </td>
                                    <td className="px-4 py-3 whitespace-nowrap">
                                      {editingSubtask && 
                                       editingSubtask.taskId === task.id && 
                                       editingSubtask.subtaskId === subtask.id ? (
                                        <input
                                          type="text"
                                          value={newSubtask.assignee}
                                          onChange={(e) => setNewSubtask({...newSubtask, assignee: e.target.value})}
                                          className="w-full border rounded px-2 py-1"
                                          list="assigneeList"
                                        />
                                      ) : (
                                        <span className="px-2 py-1 text-xs bg-blue-100 text-blue-800 rounded-full">
                                          {subtask.assignee}
                                        </span>
                                      )}
                                    </td>
                                    <td className="px-4 py-3 whitespace-nowrap">
                                      {editingSubtask && 
                                       editingSubtask.taskId === task.id && 
                                       editingSubtask.subtaskId === subtask.id ? (
                                        <select
                                          value={newSubtask.status}
                                          onChange={(e) => setNewSubtask({...newSubtask, status: e.target.value})}
                                          className="border rounded px-2 py-1"
                                        >
                                          <option value={STATUS_TYPES.TODO}>待辦</option>
                                          <option value={STATUS_TYPES.IN_PROGRESS}>進行中</option>
                                          <option value={STATUS_TYPES.COMPLETED}>已完成</option>
                                        </select>
                                      ) : (
                                        <div className="flex items-center">
                                          {getStatusIcon(subtask.status)}
                                          <span className="ml-1 text-sm text-gray-700">
                                            {subtask.status}
                                          </span>
                                        </div>
                                      )}
                                    </td>
                                    <td className="px-4 py-3 whitespace-nowrap text-sm">
                                      {editingSubtask && 
                                       editingSubtask.taskId === task.id && 
                                       editingSubtask.subtaskId === subtask.id ? (
                                        <div className="flex items-center space-x-2">
                                          <button
                                            onClick={saveSubtaskEdit}
                                            className="text-green-600 hover:text-green-800"
                                            title="保存"
                                          >
                                            <Save size={18} />
                                          </button>
                                          <button
                                            onClick={cancelEditSubtask}
                                            className="text-red-600 hover:text-red-800"
                                            title="取消"
                                          >
                                            <X size={18} />
                                          </button>
                                        </div>
                                      ) : (
                                        <div className="flex items-center space-x-2">
                                          {subtask.status !== STATUS_TYPES.TODO && (
                                            <button 
                                              onClick={() => handleSubtaskStatusChange(task.id, subtask.id, STATUS_TYPES.TODO)}
                                              className="text-yellow-600 hover:text-yellow-800"
                                              title="設為待辦"
                                            >
                                              <ListTodo size={16} />
                                            </button>
                                          )}
                                          {subtask.status !== STATUS_TYPES.IN_PROGRESS && (
                                            <button 
                                              onClick={() => handleSubtaskStatusChange(task.id, subtask.id, STATUS_TYPES.IN_PROGRESS)}
                                              className="text-blue-600 hover:text-blue-800"
                                              title="設為進行中"
                                            >
                                              <Clock size={16} />
                                            </button>
                                          )}
                                          {subtask.status !== STATUS_TYPES.COMPLETED && (
                                            <button 
                                              onClick={() => handleSubtaskStatusChange(task.id, subtask.id, STATUS_TYPES.COMPLETED)}
                                              className="text-green-600 hover:text-green-800"
                                              title="設為已完成"
                                            >
                                              <Check size={16} />
                                            </button>
                                          )}
                                          <button
                                            onClick={() => startEditSubtask(task.id, subtask)}
                                            className="text-gray-600 hover:text-gray-800"
                                            title="編輯"
                                          >
                                            <Edit size={16} />
                                          </button>
                                        </div>
                                      )}
                                    </td>
                                  </tr>
                                ))}
                              </tbody>
                            </table>
                          </div>
                          
                          {/* 添加子任務表單 */}
                          <div className="bg-white rounded-md shadow p-4">
                            <h4 className="text-md font-medium text-gray-700 mb-3">添加新子任務</h4>
                            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                              <div>
                                <label className="block text-xs text-gray-500 mb-1">子任務名稱</label>
                                <input
                                  type="text"
                                  value={newSubtask.name}
                                  onChange={(e) => setNewSubtask({...newSubtask, name: e.target.value})}
                                  className="w-full border rounded-md px-3 py-2"
                                  placeholder="輸入子任務名稱"
                                />
                              </div>
                              <div>
                                <label className="block text-xs text-gray-500 mb-1">負責人</label>
                                <input
                                  type="text"
                                  value={newSubtask.assignee}
                                  onChange={(e) => setNewSubtask({...newSubtask, assignee: e.target.value})}
                                  className="w-full border rounded-md px-3 py-2"
                                  placeholder="輸入負責人"
                                  list="assigneeList"
                                />
                                <datalist id="assigneeList">
                                  {assignees.map((assignee, index) => (
                                    <option key={index} value={assignee} />
                                  ))}
                                </datalist>
                              </div>
                              <div>
                                <label className="block text-xs text-gray-500 mb-1">狀態</label>
                                <select
                                  value={newSubtask.status}
                                  onChange={(e) => setNewSubtask({...newSubtask, status: e.target.value})}
                                  className="w-full border rounded-md px-3 py-2"
                                >
                                  <option value={STATUS_TYPES.TODO}>待辦</option>
                                  <option value={STATUS_TYPES.IN_PROGRESS}>進行中</option>
                                  <option value={STATUS_TYPES.COMPLETED}>已完成</option>
                                </select>
                              </div>
                            </div>
                            <div className="flex justify-end mt-3">
                              <button
                                onClick={() => handleAddSubtask(task.id)}
                                className="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded-md flex items-center"
                              >
                                <Plus size={16} className="mr-1" /> 添加子任務
                              </button>
                            </div>
                          </div>
                        </div>
                      </td>
                    </tr>
                  )}
                </React.Fragment>
              ))
            )}
          </tbody>
        </table>
      </div>
      
      {/* 導入任務對話框 */}
      {showImport && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-lg p-6 w-full max-w-md">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-bold text-gray-800">導入任務</h2>
              <button onClick={() => {
                setShowImport(false);
                setImportError('');
                setImportSuccess(false);
                if (fileInputRef.current) {
                  fileInputRef.current.value = '';
                }
              }} className="text-gray-500 hover:text-gray-700">
                <X size={20} />
              </button>
            </div>
            
            {importError && (
              <div className="mb-4 bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded flex items-start">
                <AlertCircle size={18} className="text-red-500 mr-2 mt-0.5" />
                <span>{importError}</span>
              </div>
            )}
            
            {importSuccess && (
              <div className="mb-4 bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded flex items-start">
                <Check size={18} className="text-green-500 mr-2 mt-0.5" />
                <span>任務導入成功！</span>
              </div>
            )}
            
            <div className="mb-4">
              <p className="text-gray-700 mb-2">選擇CSV或JSON文件導入任務列表</p>
              <input 
                type="file"
                ref={fileInputRef}
                onChange={handleFileImport}
                accept=".csv,.json"
                className="w-full text-gray-700 border rounded-md p-2"
              />
            </div>
            
            <div className="mt-6">
              <h3 className="text-lg font-medium text-gray-700 mb-2">CSV格式範例</h3>
              <div className="bg-gray-100 p-3 rounded-md text-sm font-mono">
                parent_id,id,name,category,assignee,status<br />
                ,1.1,展覽預算表,展場規劃與設計,Wilson Chen,進行中<br />
                1.1,1.1.1,外包設計,,,待辦
              </div>
            </div>
            
            <div className="mt-6">
              <h3 className="text-lg font-medium text-gray-700 mb-2">JSON格式範例</h3>
              <div className="bg-gray-100 p-3 rounded-md text-sm font-mono">
                [<br />
                &nbsp;&nbsp;&#123;<br />
                &nbsp;&nbsp;&nbsp;&nbsp;"id": "1.1",<br />
                &nbsp;&nbsp;&nbsp;&nbsp;"name": "展覽預算表",<br />
                &nbsp;&nbsp;&nbsp;&nbsp;"category": "展場規劃與設計",<br />
                &nbsp;&nbsp;&nbsp;&nbsp;"assignee": "Wilson Chen",<br />
                &nbsp;&nbsp;&nbsp;&nbsp;"status": "進行中",<br />
                &nbsp;&nbsp;&nbsp;&nbsp;"subtasks": [<br />
                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;{<br />
                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"id": "1.1.1",<br />
                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"name": "外包設計",<br />
                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"assignee": "一如設計公司",<br />
                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"status": "進行中"<br />
                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}<br />
                &nbsp;&nbsp;&nbsp;&nbsp;]<br />
                &nbsp;&nbsp;&#125;<br />
                ]
              </div>
            </div>
            
            <div className="flex justify-end mt-6">
              <button
                onClick={() => {
                  setShowImport(false);
                  setImportError('');
                  setImportSuccess(false);
                  if (fileInputRef.current) {
                    fileInputRef.current.value = '';
                  }
                }}
                className="px-4 py-2 bg-gray-200 text-gray-700 rounded-md hover:bg-gray-300"
              >
                關閉
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default SemiconTaskTracker;
