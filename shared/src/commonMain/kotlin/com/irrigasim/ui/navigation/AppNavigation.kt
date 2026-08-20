package com.irrigasim.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue

@Stable
class AppNavigationState(initialRoute: ScreenRoute) {

    var currentRoute by mutableStateOf(initialRoute)
        private set

    var selectedTab by mutableStateOf(initialRoute.tabIndex ?: 0)
        private set

    val canGoBack: Boolean
        get() = backStack.isNotEmpty()

    private val backStack = mutableStateListOf<ScreenRoute>()

    fun navigate(route: ScreenRoute) {
        if (route == currentRoute) return
        backStack.add(currentRoute)
        currentRoute = route
    }

    fun goBack(): Boolean {
        val previous = backStack.removeLastOrNull() ?: return false
        currentRoute = previous
        previous.tabIndex?.let { selectedTab = it }
        return true
    }

    fun selectTab(index: Int) {
        val tab = index.coerceIn(0, ScreenRoute.TAB_ROOTS.lastIndex)
        selectedTab = tab
        backStack.clear()
        currentRoute = ScreenRoute.TAB_ROOTS[tab]
    }

    fun resetTo(route: ScreenRoute) {
        backStack.clear()
        currentRoute = route
        route.tabIndex?.let { selectedTab = it }
    }

    fun onPagerSettled(page: Int) {
        if (!currentRoute.isTabRoot) return
        if (page != selectedTab) selectTab(page)
    }
}

@Composable
fun rememberAppNavigationState(initialRoute: ScreenRoute): AppNavigationState =
    remember { AppNavigationState(initialRoute) }
