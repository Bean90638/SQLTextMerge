#!/usr/bin/env python
# coding: utf-8

# In[1]:


import os
import glob
import tkinter as tk
import tkinter.messagebox
from numba import jit
#@jit(nopython=True)
# @numba.jit


# In[2]:


#讀檔
def ReadText(path):
    try:
        #嘗試用UTF-8格式讀檔案
        with open(path, mode='r', encoding='utf-8') as file:
            text = file.read()
        return text
    except:
        pass

    try:
        #嘗試用big5格式讀檔案
        with open(path, mode='r', encoding='big5') as file:
            text = file.read()
        return text
    except Exception as e:
        return e


#寫檔
def WriteText(data, path):
    #判斷路徑是否./
    if (path[0:2] != './'):
        path = './' + path

    #輸出前取代掉全部的ZERO WIDTH NO-BREAK SPACE
    data = data.replace(u'\ufeff', '')

    try:
        #嘗試用UTF-8格式寫檔案
        with open(path, mode='w', encoding='utf-8') as file:
            file.write(data)
        return 'utf-8'
    except:
        pass

    try:
        #嘗試用big5格式寫檔案
        with open(path, mode='w', encoding='big5') as file:
            file.write(data)
        return 'big5'
    except Exception as e:
        return e


# In[3]:


# 取代SQL文件特定字元
def Replace(d, p):
    if (not cb_intvar[p].get()):
        d = d.replace("CREATE PROCEDURE", "ALTER PROCEDURE")
        d = d.replace("CREATE VIEW", "ALTER VIEW")
        d = d.replace("CREATE FUNCTION", "ALTER FUNCTION")
    return d


# In[25]:


def button_check():
    if (s2.get()):
        FName = s2.get()
    else:
        FName = 'all'

    if (t2.get() == ''):
        tk.messagebox.showinfo('錯誤', '請輸入資料庫名稱。')
        return

    try:
        if (filenum < 1):
            tk.messagebox.showinfo('錯誤', '錯誤:該層目錄無SQL文件。')

        if (r2_var.get() == '0'):  ###合併成一個SQL檔###
            data = u'USE[' + t2.get() + u']\nGO\n\n'

            #讀取檔案
            for p, path in enumerate(filepath):
                data += Replace(ReadText(path), p) + u'\nGO\n\n'

            # 寫入檔案
            WriteText(data, './' + FName + '.sql')

        elif (r2_var.get() == '1'):  ###各檔案修改###
            for p, path in enumerate(filepath):
                #讀取檔案
                data = 'USE[' + t2.get() + ']\nGO\n\n' + Replace(
                    ReadText(path), p) + '\nGO\n\n'
                # 寫入檔案
                WriteText(data, path)

    except Exception as e:
        tk.messagebox.showinfo('錯誤', '錯誤:' + str(e))

    else:
        tk.messagebox.showinfo('修改完成', '共操作 ' + str(filenum) + ' 個檔案。')


# In[5]:


# 說明跳窗
def show_about():
    tk.messagebox.showinfo(
        '功能說明',
        '1.讀取同一層目錄裡的所有.sql檔案\n2.勾選的檔案將調整維持Create，其他更新為Alter\n3.是否將檔案合併成一個(名稱預設all.sql)\n\n作者 : Brad'
    )


# In[21]:


# 焦點移入時全選
def s2_Callback(event):
#     s2.tag_add('sel', '1.0', 'end') #text用此行，Entry用下面兩行
    s2.focus()
    s2.selection_range(0, 'end')
    return 'break'


def t2_Callback(event):
#     t2.tag_add('sel', '1.0', 'end')
    t2.focus()
    t2.selection_range(0, 'end')
    return 'break'


#     t2.selection_range(0, t2_var.end)
#     return 'break'


# In[33]:



# 取得路徑底下的所有檔名
filepath = glob.glob(r"*.sql")
filenum = len(filepath)

# 創造視窗
window = tk.Tk()
window.title('SQL文件合併')  # 視窗標題
# window.lift()
# window.attributes("-topmost", True)
# window.geometry('300x300')  # 視窗的大小(長X寬)

# 建立菜單欄
menubar = tk.Menu(window)
filemenu = tk.Menu(menubar, tearoff=0)
menubar.add_cascade(label='關於', menu=filemenu)
filemenu.add_command(label='說明', command=show_about)
window.config(menu=menubar)

# 資料庫名稱
t2_var = tk.StringVar()
# t2_var.set('DBS')
t1 = tk.Label(window,height=1, width=15, text='資料庫名稱:')
t2 = tk.Entry(window, width=15)
t2.bind("<FocusIn>", t2_Callback) # 焦點移入時全選
t2.insert(tk.END,'DBS')
t2.focus() #窗口開啟時聚焦於此

# 合併檔案名稱
s2_var = tk.StringVar()
# s2_var.set('all')
s1 = tk.Label(window,height=1, width=15, text='合併後檔名:')
s2 = tk.Entry(window, width=15)
s2.bind("<FocusIn>", s2_Callback) # 焦點移入時全選
s2.insert(tk.END,'all')

# 是否合併檔案
r2_var = tk.StringVar()
r2_var.set(0)  # 預設選項
r1 = tk.Radiobutton(window, text='合併sql檔案', variable=r2_var, value=0)
r2 = tk.Radiobutton(window, text='不合併sql檔案', variable=r2_var, value=1)

# 確認紐
b = tk.Button(window,
              text='確定',
              font=('Arial', 12),
              width=15,
              height=1,
              command=button_check)

# 勾選器說明文字
l1 = tk.Label(window,height=1, width=20, text='選擇維持Create的檔案:')

# 版面配置
t1.grid(row=0, column=0)
t2.grid(row=0, column=1)
b.grid(row=0, column=2)
s1.grid(row=1, column=0)
s2.grid(row=1, column=1)
r1.grid(row=2, column=0)
r2.grid(row=2, column=1)
l1.grid(row=3, column=0)

# 建立SQL檔案選項
column = 0  # 初始行位置
row = 5  # 初始列位置
rowtop = 10  # 列上限
cb_intvar = []  # 存勾選器別名

# @jit
def CreateCB(column):
    for this_row, text in enumerate(filepath):
        srow = row + this_row - rowtop * column
        if (srow >= rowtop + row):
            srow -= rowtop
            column += 1
        cb_intvar.append(tk.IntVar())
        tk.Checkbutton(window, text=text,variable=cb_intvar[-1]).grid(row=srow,column=column,sticky='w')
CreateCB(column)

# print(s2.get('1.0', 'end'))

# 主視窗迴圈顯示
tk.mainloop()

