import flet as ft
import pyperclip  # Для копирования текста
import psycopg2

def main(page: ft.Page):
    page.title = "SQL GUI"
    page.bgcolor = "#1a001f"
    page.padding = 0
    page.font_family = "Fira Code"
    page.window.maximized = True

    TEXT_STYLE = ft.TextStyle(size=16, weight=ft.FontWeight.BOLD, color="white")

    # SQL input field
    sql_input = ft.TextField(
        label="SQL / PLpgSQL код",
        multiline=True,
        border_color="#800080",
        text_style=TEXT_STYLE,
        border_radius=10,
        filled=True,
        fill_color="#2a0033",
        cursor_color="white",
        cursor_width=2,
        expand=True,
    )

    # Result display field
    result_output = ft.Text(
        value="",
        style=TEXT_STYLE,
        selectable=True,
        expand=True,
    )

    # Кнопки действий
    
    def run_query(e):
        query = sql_input.value.strip()
        if not query:
            result_output.value = "Поле ввода пустое"
            page.update()
            return

        try:
            conn = psycopg2.connect(
                host="localhost",
                database="zelenograd_cemetery",
                user="postgres",
                password=""
            )
            cur = conn.cursor()
            cur.execute(query)

            if cur.description:  # есть возвращаемые строки (например SELECT)
                rows = cur.fetchall()[:500]
                columns = [desc[0] for desc in cur.description]
                result_text = "\t".join(columns) + "\n" + "\n".join(["\t".join(map(str, row)) for row in rows])
            else:  # команда вроде INSERT, UPDATE
                conn.commit()
                result_text = f"Команда выполнена успешно: {cur.statusmessage}"

            cur.close()
            conn.close()

        except Exception as ex:
            import traceback
            error_details = traceback.format_exc()
            print(error_details)  # лог в консоль
            result_text = f"Ошибка при выполнении запроса:\n\n{error_details}"


        result_output.value = result_text
        page.update()

    def clear_input(e):
        sql_input.value = ""
        page.update()

    def copy_output(e):
        if result_output.value:
            pyperclip.copy(result_output.value)
            print("Скопировано в буфер обмена")

    # AppBar с навигацией
    page.appbar = ft.AppBar(
        title=ft.Text("SQL GUI Client", style=ft.TextStyle(size=20, weight=ft.FontWeight.BOLD, color="white")),
        bgcolor="#550055",
        actions=[
            ft.TextButton(content=ft.Text("ERD", weight="bold", color="white"), on_click=lambda e: print("ERD")),
            ft.TextButton(content=ft.Text("Примеры кода", weight="bold", color="white"), on_click=lambda e: print("Примеры")),
            ft.TextButton(content=ft.Text("Документация", weight="bold", color="white"), on_click=lambda e: print("Документация")),
        ]
    )

    # Левая часть (ввод + кнопки)
    input_column = ft.Column(
        [
            sql_input,
            ft.Row([
                ft.ElevatedButton("Отправить", on_click=run_query),
                ft.OutlinedButton("Очистить", on_click=clear_input),
            ], alignment=ft.MainAxisAlignment.START)
        ],
        expand=True
    )

    # Правая часть (вывод + кнопка копировать)
    output_column = ft.Column(
        [
            ft.Container(result_output, expand=True),
            ft.Row([
                ft.OutlinedButton("Скопировать", on_click=copy_output)
            ], alignment=ft.MainAxisAlignment.START)
        ],
        expand=True
    )

    # Основная строка: две колонки
    body = ft.Row(
        [
            ft.Container(input_column, padding=10, expand=1),
            ft.Container(output_column, padding=10, bgcolor="#330033", border_radius=10, border=ft.border.all(5, "black"), expand=1),
        ],
        expand=True
    )

    page.add(body)

ft.app(target=main)