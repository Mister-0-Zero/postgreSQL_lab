import flet as ft
import pyperclip  # Для копирования текста
import psycopg2
import traceback
import os


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
    
    def show_erd_view(e):
        try:
            # Полный путь к изображению
            erd_path = os.path.join(os.path.dirname(__file__), "ERD.png")
            
            # Проверяем существование файла
            if not os.path.exists(erd_path):
                raise FileNotFoundError(f"Файл ERD.png не найден по пути: {erd_path}")
            
            # Создаем View для ERD
            erd_view = ft.View(
                "/erd",
                [
                    ft.AppBar(
                        title=ft.Text("ERD Diagram"), 
                        bgcolor="#550055",
                        leading=ft.IconButton(
                            icon="arrow_back",
                            on_click=lambda _: page.go("/"),  # Возврат на главный экран
                        )
                    ),
                    ft.Container(
                        content=ft.Column(
                            [
                                ft.Image(
                                    src=erd_path,
                                    fit="contain"
                                ),
                                ft.Text("Диаграмма ERD базы данных", size=16),
                            ],
                            horizontal_alignment="center",
                        ),
                        expand=True,
                        padding=20,
                        alignment=ft.alignment.center,
                    )
                ],
                scroll="auto",
                padding=0,
            )
            
            page.views.clear()
            page.views.append(erd_view)
            page.update()
            
        except Exception as ex:
            error_msg = f"Ошибка при загрузке ERD: {str(ex)}"
            print(error_msg)
            page.snack_bar = ft.SnackBar(
                ft.Text(error_msg),
                bgcolor="#FF0000",
            )
            page.snack_bar.open = True
            page.update()

    def show_examples_view(e):
        try:
            # Загружаем примеры из файла
            with open("examples.md", "r", encoding="utf-8") as f:
                examples_content = f.read()
            
            # Создаем View для примеров
            examples_view = ft.View(
                "/examples",
                [
                    ft.AppBar(title=ft.Text("Примеры SQL запросов"), bgcolor="#550055"),
                    ft.Container(
                        content=ft.Column(
                            [
                                ft.Markdown(
                                    examples_content,
                                    selectable=True,
                                    extension_set=ft.MarkdownExtensionSet.GITHUB_WEB,
                                    code_theme="atom-one-dark",
                                    on_tap_link=lambda e: page.launch_url(e.data),
                                )
                            ],
                            expand=True,
                            scroll="auto"
                        ),
                        expand=True,
                        padding=20,
                    ),
                    ft.FloatingActionButton(
                        icon=ft.icons.COPY,
                        text="Копировать выделенный текст",
                        on_click=lambda e: copy_selected_text(),
                        bgcolor="#800080",
                    )
                ],
                scroll="auto"
            )
            page.views.append(examples_view)
            page.update()
        except Exception as ex:
            page.snack_bar = ft.SnackBar(ft.Text(f"Ошибка при загрузке примеров: {ex}"))
            page.snack_bar.open = True
            page.update()

    def copy_selected_text():
        # Эта функция будет копировать выделенный текст в Markdown-виджете
        # Реализация зависит от того, как Flet обрабатывает выделение текста
        pass

    def show_query_view(e=None):
        page.views.clear()
        page.views.append(query_view)
        page.update()

    def show_doc_view(e=None):
        readme_text = load_readme()
        doc_page = ft.View(
            "/docs",
            [
                ft.AppBar(
                    title=ft.Text("Документация"), 
                    bgcolor="#550055",
                    leading=ft.IconButton(
                        icon="arrow_back",
                        on_click=lambda _: page.go("/"),  # Возврат на главный экран
                    )
                ),
                ft.Container(
                    content=ft.Column([
                        ft.Markdown(
                            readme_text,
                            selectable=True,
                            extension_set="gitHubWeb",
                            code_theme="atom-one-dark",
                            on_tap_link=lambda e: page.launch_url(e.data),
                            expand=True,
                        )
                    ], expand=True, scroll="auto"),
                    expand=True,
                    bgcolor="#110011",
                    padding=20
                )
            ],
            scroll="auto"
        )
        page.views.clear()
        page.views.append(doc_page)
        page.update()

    def load_readme():
        try:
            base_dir = os.path.dirname(os.path.abspath(__file__))  # папка, где main.py
            readme_path = os.path.join(base_dir, "..", "README.md")
            with open(readme_path, "r", encoding="utf-8") as f:
                return f.read()
        except Exception as e:
            return f"Не удалось загрузить документацию:\n\n{e}"

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
                if len(rows) == 500:
                    result_text += "\n...\nОграничено 500 строками."
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

    query_view = ft.View(
        "/",
        appbar = ft.AppBar(
            title=ft.Text("SQL GUI Client", style=ft.TextStyle(size=20, weight=ft.FontWeight.BOLD, color="white")),
            bgcolor="#330033",
            actions=[
                ft.TextButton(content=ft.Text("Запросчик", weight="bold", color="white"), on_click=show_query_view),
                ft.TextButton(content=ft.Text("ERD", weight="bold", color="white"), on_click=show_erd_view),
                ft.TextButton(content=ft.Text("Примеры кода", weight="bold", color="white"), on_click=show_examples_view),
                ft.TextButton(content=ft.Text("Документация", weight="bold", color="white"), on_click=show_doc_view),
            ]
        ),
        controls=[
            ft.Row(
                [
                    ft.Container(
                        input_column,
                        padding=20,
                        expand=True,
                        bgcolor="#220022",
                        border_radius=10,
                    ),
                    ft.Container(
                        output_column,
                        padding=20,
                        expand=True,
                        bgcolor="#330033",
                        border_radius=10,
                    ),
                ],
                expand=True,
                spacing=10,
            )
        ],
        padding=0,
        spacing=0,
    )

    def route_change(e):
        if page.route == "/":
            show_query_view()
        elif page.route == "/erd":
            show_erd_view(None)
        elif page.route == "/docs":
            show_doc_view(None)

    page.on_route_change = route_change

    page.views.append(query_view)
    page.update()

    error_details = traceback.format_exc()
    print(error_details)
    result_text = f"Ошибка при выполнении запроса:\n\n{error_details}"




ft.app(target=main)