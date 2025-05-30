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
                                    fit="contain",
                                    width=page.window_width * 0.9,
                                    height=page.window_height * 0.8,
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